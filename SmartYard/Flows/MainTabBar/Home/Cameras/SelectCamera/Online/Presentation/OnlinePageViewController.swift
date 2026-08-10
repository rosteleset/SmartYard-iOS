import UIKit
import RxSwift
import RxCocoa
import SmartYardVideoPlayer

protocol OnlinePageViewControllerDelegate: AnyObject {
    func onlinePageViewController(_ vc: OnlinePageViewController, didSelectCameraId id: CameraID)
}

final class OnlinePageViewController: BaseViewController {

    // MARK: - Dependencies

    private let viewModel: OnlinePageViewModel

    private var collectionBinder: OnlineCollectionBinder?
    private var playbackCoordinator: OnlinePlaybackCoordinating?

    private var playbackBinder: OnlinePlaybackBinder?
    private let selectionNavigator = OnlineSelectionNavigator()

    // MARK: - State (UI only)

    private var isTransitioningToFullscreen = false
    private var hasAppearedOnce = false
    private var pendingFullscreenRestoreIndex: Int?
    private var lockedCenteredIndexAfterFullscreen: Int?

    private let config = OnlinePageContext(
        cameras: BehaviorRelay<[CameraViewModel]>(value: []),
        preselectedCameraId: BehaviorRelay<CameraID?>(value: nil)
    )

    private let events = OnlinePageEvents()

    private var output: OnlinePageViewModel.Output?
    private var latestState: OnlinePageState?

    weak var delegate: OnlinePageViewControllerDelegate?

    // MARK: - UI

    private lazy var collectionView: UICollectionView = {
        let layout = OnlinePageLayoutBuilder().makeLayout(
            onTopCenteredIndex: { [weak self] index in
                guard let self else { return }
                if let lockedIndex = self.lockedCenteredIndexAfterFullscreen {
                    Logger.logDebug("ignore centered index=\(index) locked=\(lockedIndex)")
                    return
                }
                guard self.selectionNavigator.shouldForwardTopCenteredIndex(index) else { return }
                self.events.didCenterMainIndex.accept(index)
            }
        )

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.allowsSelection = true
        cv.allowsMultipleSelection = false
        return cv
    }()

    // MARK: - Init

    init(viewModel: OnlinePageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = L10n.Camera.Online.title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.logDebug("viewDidLoad")

        view.addSubview(collectionView)
        addInlineSelectionUnlockGesture()

        bind()
        events.viewDidLoad.accept(())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.safeAreaLayoutGuide.layoutFrame
        selectionNavigator.onCollectionLayout(collectionView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Logger.logDebug("viewWillAppear")
        configureInlinePlaybackControls()
        events.viewWillAppear.accept(())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Logger.logDebug("viewDidAppear")
        events.viewDidAppear.accept(())
        guard hasAppearedOnce else {
            hasAppearedOnce = true
            return
        }
        if let pendingFullscreenRestoreIndex {
            self.pendingFullscreenRestoreIndex = nil
            restoreInlineSelection(index: pendingFullscreenRestoreIndex)
            playbackBinder?.restoreAfterFullscreen(selectedIndex: pendingFullscreenRestoreIndex, retryCount: 3)
        } else {
            playbackBinder?.restorePlayback()
        }
        playbackBinder?.restoreCloseHandler()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Logger.logDebug(
            "viewWillDisappear movingFromParent=\(isMovingFromParent) beingDismissed=\(isBeingDismissed)"
        )
        if isMovingFromParent || isBeingDismissed {
            playbackCoordinator?.setCloseHandler(nil)
        }

        if !isMovingFromParent && !isBeingDismissed && !isTransitioningToFullscreen {
            playbackCoordinator?.stopHard()
        }

        events.viewWillDisappear.accept(())
    }

    // MARK: - Public API

    func applyConfiguration(
        cameras: [CameraObject],
        preselectedCameraId: CameraID
    ) {
        Logger.logDebug("applyConfiguration cameras=\(cameras.count) preselectedId=\(preselectedCameraId)")
        if !cameras.contains(where: { $0.id == preselectedCameraId }) {
            Logger.logDebug("preselectedId not found id=\(preselectedCameraId)")
        }

        // Provider ресурсов
        let streamProvider = CameraStreamProvider(
            cameras: cameras,
            ttl: 120,
            transportPolicy: .hlsOnly
        )

        // Playback coordinator
        let playback = OnlinePlaybackCoordinator(provider: streamProvider)
        playbackCoordinator = playback
        configureInlinePlaybackControls()

        // Section controllers
        let sectionProvider = OnlineSectionControllersProvider(
            playbackCoordinator: playback,
            events: events
        )

        // Binder (тупой)
        let binder = OnlineCollectionBinder(provider: sectionProvider)
        binder.onSectionsUpdated = { [weak self, weak binder] sections in
            guard let self else { return }
            self.selectionNavigator.onSectionsUpdated(sections, collectionView: self.collectionView)
            _ = binder // чтобы не ругалось на unused в некоторых конфигурациях
        }
        collectionBinder = binder

        // Bind binder -> collection (если output уже готов)
        if let output {
            binder.bind(collectionView: collectionView, sections: output.sections)
        }

        // Playback binder
        let pb = OnlinePlaybackBinder(collectionView: collectionView, playback: playback)
        playbackBinder = pb

        if let output {
            pb.bind(
                state: output.state,
                onRequestFullscreen: { [weak self] index in
                    self?.presentFullscreen(startingAt: index)
                },
                disposeBag: disposeBag
            )
        }

        // Конфиг VM
        let viewModels = makeCameraVMs(from: cameras)
        config.cameras.accept(viewModels)
        config.preselectedCameraId.accept(preselectedCameraId)
    }
}

// MARK: - Bind

private extension OnlinePageViewController {
    func bind() {
        Logger.logDebug("bind")
        let input = OnlinePageViewModel.Input(context: config, events: events)
        let output = viewModel.transform(input)
        self.output = output

        // 1) state just to keep latestState + delegate notify
        output.state
            .drive(with: self) { owner, state in
                owner.latestState = state
            }
            .disposed(by: disposeBag)

        output.state
            .map { ($0.selectedCameraId, $0.cameras.isEmpty) }
            .filter { !$0.1 }
            .map(\.0)
            .distinctUntilChanged()
            .drive(with: self) { owner, id in
                owner.delegate?.onlinePageViewController(owner, didSelectCameraId: id)
            }
            .disposed(by: disposeBag)

        // 2) sections -> binder
        if let collectionBinder {
            collectionBinder.bind(collectionView: collectionView, sections: output.sections)
        }

        // 3) selection -> navigator
        output.selection
            .emit(with: self) { owner, intent in
                owner.selectionNavigator.apply(intent, in: owner.collectionView)
            }
            .disposed(by: disposeBag)

        // 4) playback binder
        if let playbackBinder {
            playbackBinder.bind(
                state: output.state,
                onRequestFullscreen: { [weak self] index in
                    self?.presentFullscreen(startingAt: index)
                },
                disposeBag: disposeBag
            )
        }

        collectionView.rx.methodInvoked(#selector(UIView.layoutSubviews))
            .subscribe(with: self) { owner, _ in
                owner.selectionNavigator.onCollectionLayout(owner.collectionView)
            }
            .disposed(by: disposeBag)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension OnlinePageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

// MARK: - Resource

private extension OnlinePageViewController {

    func makeResource(from camera: CameraObject) -> SYPlayerResource {
        let preview = URL(string: camera.previewURL)
        let url = URL(string: camera.baseURLString)!
        var videos: [SYPlayerResourceVideo] = []

        if let whepURL = camera.whepURL {
            videos.append(SYPlayerResourceVideo(whepEndpointURL: whepURL))
        }
        videos.append(SYPlayerResourceVideo(url: url))

        return SYPlayerResource(
            videos: videos,
            previewImage: preview,
            name: camera.name,
            videoType: .online,
            hasSound: camera.hasSound
        )
    }

    func makeCameraVMs(from cameras: [CameraObject]) -> [CameraViewModel] {
        cameras.enumerated().map { index, camera in
            makeCameraVM(from: camera, index: index)
        }
    }

    func makeCameraVM(from camera: CameraObject, index: Int) -> CameraViewModel {
        CameraViewModel(
            identity: "\(index)_\(camera.id)",
            id: camera.id,
            number: camera.cameraNumber,
            resource: makeResource(from: camera),
            isMuted: !camera.hasSound
        )
    }
}

// MARK: - Fullscreen

private extension OnlinePageViewController {

    func presentFullscreen(startingAt index: Int) {
        guard presentedViewController == nil else {
            Logger.logDebug("presentFullscreen blocked: already presented")
            return
        }
        guard let state = latestState else {
            Logger.logError("presentFullscreen blocked: missing state")
            return
        }
        guard let playbackCoordinator else {
            Logger.logError("presentFullscreen blocked: missing playbackCoordinator")
            return
        }
        guard !state.cameras.isEmpty else {
            Logger.logError("presentFullscreen blocked: empty cameras")
            return
        }
        guard state.cameras.indices.contains(index) else {
            Logger.logError("presentFullscreen blocked: missing index=\(index)")
            return
        }

        Logger.logDebug("presentFullscreen start index=\(index) id=\(state.cameras[index].id)")
        logCameraFullscreenOpened()

        isTransitioningToFullscreen = true

        let vc = OnlineFullscreenViewController(
            cameras: state.cameras,
            initialIndex: index,
            playback: playbackCoordinator,
            onDismiss: { [weak self] selectedIndex in
                guard let self else { return }
                Logger.logDebug("fullscreen onDismiss index=\(selectedIndex)")
                self.pendingFullscreenRestoreIndex = selectedIndex
                self.restoreInlineSelection(index: selectedIndex)
                // триггерим обычный путь: events -> VM -> selectionIntent -> navigator
                self.events.didTapPreviewIndex.accept(selectedIndex)

                // меняем режим на обычный
                self.playbackCoordinator?.setMode(.default)
                self.configureInlinePlaybackControls()

                // чуть поможем attach-у (на всякий)
                self.playbackBinder?.restoreAfterFullscreen(selectedIndex: selectedIndex, retryCount: 3)
                self.playbackBinder?.restoreCloseHandler()
            }
        )

        playbackCoordinator.setMode(.fullscreen)
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: true) { [weak self] in
            self?.isTransitioningToFullscreen = false
        }
    }

    func restoreInlineSelection(index: Int) {
        guard let state = latestState else {
            Logger.logError("restoreInlineSelection blocked: missing state index=\(index)")
            return
        }
        guard state.cameras.indices.contains(index) else {
            Logger.logError("restoreInlineSelection missing index=\(index) cameras=\(state.cameras.count)")
            return
        }

        lockedCenteredIndexAfterFullscreen = index
        selectionNavigator.apply(
            OnlineSelectionIntent(index: index, cameraId: state.cameras[index].id, source: .numberTap),
            in: collectionView
        )
        collectionView.layoutIfNeeded()
    }

    func addInlineSelectionUnlockGesture() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleInlineSelectionPan(_:)))
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        collectionView.addGestureRecognizer(gesture)
    }

    @objc func handleInlineSelectionPan(_ recognizer: UIPanGestureRecognizer) {
        guard recognizer.state == .began else { return }
        lockedCenteredIndexAfterFullscreen = nil
    }

    func logCameraFullscreenOpened() {
        AppAnalytics.log(
            AppAnalyticsEvent.cameraFullscreenOpened(
                source: "camera_details",
                cameraType: AnalyticsValue.unknown,
                streamType: "live"
            )
        )
    }
}

// MARK: - Playback Controls

private extension OnlinePageViewController {
    func configureInlinePlaybackControls() {
        playbackCoordinator?.setControlsAutoHideEnabled(false)
    }
}
