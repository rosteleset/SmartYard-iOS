//
//  OnlinePageViewController.swift
//  SmartYard
//
//  Created by admin on 15.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable type_body_length function_body_length line_length file_length

import UIKit
import RxSwift
import RxCocoa
import AVKit
import TouchAreaInsets
import Lottie

protocol OnlinePageViewControllerDelegate: AnyObject {
    
    func onlinePageViewController(_ vc: OnlinePageViewController, didSelectCamera camera: CameraObject)
    func onlinePageViewController(_ vc: OnlinePageViewController, didSortCameras camIds: [Int])
    
}

class OnlinePageViewController: BaseViewController {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var cameraContainer: UIView!
    @IBOutlet private weak var muteButton: UIButton!
    @IBOutlet private weak var fullscreenButton: UIButton!
    @IBOutlet private weak var videoLoadingAnimationView: LottieAnimationView!
    
    fileprivate var longPressGesture: UILongPressGestureRecognizer!
    
    private var apiWrapper: APIWrapper

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    @IBOutlet private var collectionViewHeightConstraint: NSLayoutConstraint!
    
    private var cameras = [CameraObject]()
    private var selectedCamera: CameraObject?
    private var selectedCameraNumber: Int?
    private var cameraFullscreen: Bool
    
    private var loadingAsset: AVAsset?
    
    private let isVideoValid = BehaviorSubject<Bool>(value: false)
    private let isVideoBeingLoaded = BehaviorSubject<Bool>(value: false)
    private let itemSelected = BehaviorSubject<CameraObject?>(value: nil)

    weak var delegate: OnlinePageViewControllerDelegate?
    
    init(apiWrapper: APIWrapper) {
        self.apiWrapper = apiWrapper
        self.cameraFullscreen = false

        super.init(nibName: nil, bundle: nil)
        
        title = "Онлайн"
    }
    
    init(apiWrapper: APIWrapper, fullscreen: Bool) {
        self.apiWrapper = apiWrapper
        self.cameraFullscreen = fullscreen

        super.init(nibName: nil, bundle: nil)
        
        title = "Онлайн"
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        player?.replaceCurrentItem(with: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePlayer()
        configureFullscreenButton()
        configureMuteButton()
        configureCollectionView()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !cameraFullscreen {
            playerLayer?.frame = cameraContainer.bounds
        }
//        guard let selectedCamera = selectedCamera else {
//            return
//        }
//        let indexPath = IndexPath(row: selectedCamera.cameraNumber, section: 0)
//        scrollToCenter(indexPath)
    }
    
    func setCameras(_ cameras: [CameraObject], selectedCamera: CameraObject?) {
        self.cameras = cameras
        self.selectedCamera = selectedCamera
        
        collectionView.reloadData { [weak self] in
            guard let self = self,
                  let selectedCamera = selectedCamera,
                  let index = cameras.firstIndex(of: selectedCamera),
                  let camera = (cameras.first { $0.cameraNumber == selectedCamera.cameraNumber }) else {
                return
            }

            let indexPath = IndexPath(row: index, section: 0)

            self.collectionView.selectItem(
                at: indexPath,
                animated: false,
                scrollPosition: .top
            )
            self.itemSelected.onNext(camera)
            self.reloadCameraIfNeeded(row: camera.cameraNumber)
            self.scrollToCenter(camera)

            if self.cameraFullscreen {
                self.showFullscreen()
            }
        }
    }
    
    private func scrollToCenter(_ camera: CameraObject) {
        let top = camera.cameraNumber.cgFloat * 54 - scrollView.bounds.height / 2
        guard top > 0 else {
            return
        }
        let maxTop = collectionViewHeightConstraint.constant - scrollView.bounds.height

        guard top < maxTop else {
            scrollView.contentOffset = CGPoint(x: 0, y: maxTop)
            return
        }
        scrollView.contentOffset = CGPoint(x: 0, y: top)
    }
    
    private func bind() {
        
        isVideoBeingLoaded
            .asDriver(onErrorJustReturn: false)
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.videoLoadingAnimationView.isHidden = !isLoading
                    
                    if isLoading {
                        self?.videoLoadingAnimationView.play()
                    } else {
                        self?.videoLoadingAnimationView.stop()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        isVideoValid
            .asDriver(onErrorJustReturn: false)
            .drive(
                onNext: { [weak self] isVideoValid in
                    self?.fullscreenButton.isHidden = !isVideoValid
                    self?.muteButton.isHidden = !isVideoValid
                }
            )
            .disposed(by: disposeBag)
        
        // При уходе с окна или при сворачивании приложения - паузим плеер
        
        Driver
            .merge(
                NotificationCenter.default.rx
                    .notification(UIApplication.didEnterBackgroundNotification)
                    .asDriverOnErrorJustComplete()
                    .mapToVoid(),
                rx.viewDidDisappear
                    .asDriver()
                    .mapToVoid()
            )
            .drive(
                onNext: { [weak self] _ in
                    self?.player?.pause()
                }
            )
            .disposed(by: disposeBag)
        
        // При заходе на окно - запускаем плеер
        
        rx.viewDidAppear
            .asDriver()
            .drive(
                onNext: { [weak self] _ in
                    self?.player?.play()
                }
            )
            .disposed(by: disposeBag)
        
        // При разворачивании приложения (если окно открыто) - запускаем плеер
        
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(rx.isVisible.asDriverOnErrorJustComplete())
            .isTrue()
            .drive(
                onNext: { [weak self] _ in
                    self?.player?.play()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configurePlayer() {
        let player = AVPlayer()
        self.player = player
        
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
        }
        
        playerLayer = AVPlayerLayer(player: player)
        cameraContainer.layer.insertSublayer(playerLayer!, at: 0)
        playerLayer?.removeAllAnimations()
        playerLayer?.backgroundColor = UIColor.black.cgColor
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.player?.isMuted = true

        // MARK: Настройка лоадера
        
        let animation = LottieAnimation.named("LoaderAnimation")
        
        videoLoadingAnimationView.animation = animation
        videoLoadingAnimationView.loopMode = .loop
        videoLoadingAnimationView.backgroundBehavior = .pauseAndRestore
        
        // MARK: Когда полноэкранное видео будет закрыто, нужно добавить слой заново
        
        NotificationCenter.default.rx
            .notification(.onlineFullscreenModeClosed)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self, let playerLayer = self.playerLayer else {
                        return
                    }
                    playerLayer.removeFromSuperlayer()
                    self.cameraContainer.layer.insertSublayer(playerLayer, at: 0)
                    
                    playerLayer.frame = self.cameraContainer.bounds
                    playerLayer.removeAllAnimations()
                    playerLayer.videoGravity = .resizeAspectFill

                    self.player?.play()
                    self.cameraFullscreen = false
                    
                    if let player = playerLayer.player,
                       player.isMuted {
                        self.muteButton.setImage(UIImage(named: "volumeOff"), for: .normal)
                        self.muteButton.setImage(UIImage(named: "volumeOff")?.darkened(), for: [.normal, .highlighted])
                    } else {
                        self.muteButton.setImage(UIImage(named: "volumeOn"), for: .normal)
                        self.muteButton.setImage(UIImage(named: "volumeOn")?.darkened(), for: [.normal, .highlighted])
                    }

                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Проверка, валидно ли текущее видео
        
        Driver
            .combineLatest(
                player.rx
                    .observe(AVPlayer.Status.self, "status", options: [.new])
                    .asDriver(onErrorJustReturn: nil),
                player.rx
                    .observe(AVPlayerItem.self, "currentItem", options: [.new])
                    .asDriver(onErrorJustReturn: nil)
            )
            .map { args -> Bool in
                let (status, currentItem) = args
                
                guard status == .readyToPlay,
                    let asset = currentItem?.asset,
                    asset.duration.seconds > 0 || asset.duration.flags.rawValue == 17 else {
                    return false
                }
                
                return true
            }
            .drive(
                onNext: { [weak self] isVideoValid in
                    self?.isVideoValid.onNext(isVideoValid)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureMuteButton() {
        
        muteButton.setImage(UIImage(named: "volumeOff"), for: .normal)
        muteButton.setImage(UIImage(named: "volumeOff")?.darkened(), for: [.normal, .highlighted])
        
        muteButton.touchAreaInsets = UIEdgeInsets(inset: 12)
        
        // MARK: При нажатии на кнопку mute включаем или выключаем звук

        muteButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let playerLayer = self?.playerLayer else {
                        return
                    }
                    
                    playerLayer.player?.isMuted = !(playerLayer.player?.isMuted ?? true)
                    
                    if let player = playerLayer.player,
                       player.isMuted {
                        self?.muteButton.setImage(UIImage(named: "volumeOff"), for: .normal)
                        self?.muteButton.setImage(UIImage(named: "volumeOff")?.darkened(), for: [.normal, .highlighted])
                    } else {
                        self?.muteButton.setImage(UIImage(named: "volumeOn"), for: .normal)
                        self?.muteButton.setImage(UIImage(named: "volumeOn")?.darkened(), for: [.normal, .highlighted])
                    }

                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureFullscreenButton() {
        fullscreenButton.setImage(UIImage(named: "FullScreen20"), for: .normal)
        fullscreenButton.setImage(UIImage(named: "FullScreen20")?.darkened(), for: [.normal, .highlighted])
        
        fullscreenButton.touchAreaInsets = UIEdgeInsets(inset: 12)
        
        // MARK: При нажатии на кнопку фуллскрина показываем новый VC с видео на весь экран
        
        fullscreenButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    self?.showFullscreen()
                }
            )
            .disposed(by: disposeBag)
    }
    
    func showFullscreen() {
        cameraFullscreen = false
        guard let playerLayer = self.playerLayer, let camera = (cameras.first(where: { $0.cameraNumber == selectedCameraNumber })) else {
            return
        }
        let playerposition = playerLayer.superview?.convert(playerLayer.frame, to: nil)
        playerLayer.removeFromSuperlayer()
        
        let fullscreenVc = FullscreenPlayerViewController(
            playedVideoType: .online,
            preferredPlaybackRate: 1,
            position: playerposition,
            doors: camera.doors,
            apiWrapper: apiWrapper
        )
        
        fullscreenVc.modalPresentationStyle = .overFullScreen
        fullscreenVc.modalTransitionStyle = .crossDissolve
        fullscreenVc.setPlayerLayer(playerLayer)

        present(fullscreenVc, animated: true) {
            self.player?.play()
            self.cameraFullscreen = true

            if let player = playerLayer.player,
               player.isMuted {
                fullscreenVc.setMuteButton(icon: "volumeOff")
            } else {
                fullscreenVc.setMuteButton(icon: "volumeOn")
            }
        }
    }
    
    var dragPosition: CGFloat?
    
    @objc func handleLongGesture(_ gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
        case .began:
            guard let selectedIndexPath = collectionView?.indexPathForItem(at: gesture.location(in: collectionView)) else {
                break
            }
            collectionView?.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            guard let collectionView = collectionView else {
                break
            }
            var gesturelocation = gesture.location(in: collectionView)
            gesturelocation.x = collectionView.frame.width / 2 + 5
            
            if gesturelocation.y > 30, gesturelocation.y < collectionViewHeightConstraint.constant - 30 {
                collectionView.updateInteractiveMovementTargetPosition(gesturelocation)
                guard let dragPosition = dragPosition else {
                    self.dragPosition = gesturelocation.y
                    return
                }
                self.dragPosition = gesturelocation.y
                if gesturelocation.y < dragPosition {
                    if scrollView.contentOffset.y > 0 {
                        let delta = (scrollView.contentOffset.y + scrollView.frame.size.height - gesturelocation.y) / 50
                        //                        print("DELTA up", delta)
                        let newOffset = scrollView.contentOffset.y - delta
                        if newOffset > 0 {
                            scrollView.contentOffset = CGPoint(x: 0, y: newOffset)
                        } else {
                            scrollView.contentOffset = CGPoint(x: 0, y: 0)
                        }
                    }
                } else if gesturelocation.y > dragPosition {
                    if scrollView.contentOffset.y + scrollView.frame.size.height < scrollView.contentSize.height {
                        let delta = (gesturelocation.y - scrollView.contentOffset.y) / 50
                        //                        print("DELTA down", delta)
                        let newOffset = scrollView.contentOffset.y + delta
                        if newOffset < scrollView.contentSize.height - scrollView.frame.size.height {
                            scrollView.contentOffset = CGPoint(x: 0, y: newOffset)
                        } else {
                            scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.frame.size.height)
                        }
                    }
                }
            }
        case .ended, .cancelled:
            dragPosition = nil
            collectionView.reloadData()
            
            let camIds = cameras.map { $0.id }
            delegate?.onlinePageViewController(self, didSortCameras: camIds)

            if let camera = try? itemSelected.value(),
               let index = cameras.firstIndex(of: camera) {
                let indexPath = IndexPath(row: index, section: 0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    self?.collectionView.selectItem(
                        at: indexPath,
                        animated: false,
                        scrollPosition: .top
                    )
                }
            }
            collectionView?.endInteractiveMovement()
            
        default:
            dragPosition = nil
            collectionView?.cancelInteractiveMovement()
        }
    }
    
    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture(_:)))
        collectionView?.addGestureRecognizer(longPressGesture)

        collectionView.register(nibWithCellClass: CameraNameCell.self)
//        collectionView.register(nibWithCellClass: CameraNumberCell.self)
        collectionView.rx
            .observeWeakly(CGSize.self, "contentSize")
            .subscribe(
                onNext: { [weak self] size in
                    guard let self = self, let uSize = size else {
                        return
                    }
//                    print("CONTENTSIZE", uSize)
                    self.collectionViewHeightConstraint.constant = uSize.height
                    self.view.setNeedsLayout()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func reloadCameraIfNeeded(row: Int) {
//        let camera = cameras[row]
        guard let camera = (cameras.first { $0.cameraNumber == row }) else {
            return
        }
        
        print("Selected Camera #\(camera.cameraNumber)")
        
        guard camera.cameraNumber != selectedCameraNumber else {
            return
        }
        
        selectedCameraNumber = camera.cameraNumber
        
        delegate?.onlinePageViewController(self, didSelectCamera: camera)
        
        player?.replaceCurrentItem(with: nil)
        
        loadingAsset?.cancelLoading()
        loadingAsset = nil
        
        let resultingString = camera.video + "/index.m3u8" + "?token=\(camera.token)"
        
        guard let url = URL(string: resultingString) else {
            return
        }
        
        let asset = AVAsset(url: url)
        
        loadingAsset = asset
        
        isVideoBeingLoaded.onNext(true)
        playerLayer?.frame = cameraContainer.bounds

        asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) { [weak self, weak asset] in
            guard let asset = asset else {
                return
            }
            
            var tracksError: NSError?
            var durationError: NSError?
            
            let tracksStatus = asset.statusOfValue(forKey: "tracks", error: &tracksError)
            let durationStatus = asset.statusOfValue(forKey: "duration", error: &durationError)
            
            if tracksStatus == .cancelled ||
                tracksStatus == .failed ||
                durationStatus == .cancelled ||
                durationStatus == .failed {
                self?.isVideoBeingLoaded.onNext(false)
                return
            }
            
            guard tracksStatus == .loaded, durationStatus == .loaded else {
                return
            }
            
            self?.isVideoBeingLoaded.onNext(false)
            
            DispatchQueue.main.async {
                // MARK: Ассет загружен, больше хранить его не нужно
                
                self?.loadingAsset = nil
                
                // MARK: Видео готово к просмотру, засовываем его в плеер
                
                let playerItem = AVPlayerItem(asset: asset)
                
                // Необходимо для того, чтобы в HLS потоке мог быть выбран поток с разрешением превышающим разрешение экрана телефона
                playerItem.preferredMaximumResolution = CGSize(width: 3840, height: 2160)
                
                self?.player?.replaceCurrentItem(with: playerItem)
                
                if self?.isVisible == true {
                    self?.player?.play()
                }
            }
        }
    }
    
}

extension OnlinePageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer == scrollView.panGestureRecognizer
    }
}

extension OnlinePageViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cameras.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withClass: CameraNumberCell.self, for: indexPath)
        let cell = collectionView.dequeueReusableCell(withClass: CameraNameCell.self, for: indexPath)

        cell.configure(camera: cameras[indexPath.row])
        cell.cameraSelectButton.tag = indexPath.row
        cell.cameraSelectButton.addTarget(self, action: #selector(OnlinePageViewController.cameraSelectTaped(_:)), for: .touchUpInside)
        cell.cameraDragImage.tag = indexPath.row
        cell.tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(OnlinePageViewController.handleLongGesture(_:)))
        cell.tapGesture.minimumPressDuration = 0
        cell.cameraDragImage.addGestureRecognizer(cell.tapGesture)

        return cell
    }

    @objc func cameraSelectTaped(_ sender: UIButton) {
        let indexPath = IndexPath(row: sender.tag, section: 0)
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? CameraNameCell,
              let cameraNumber = cell.cameraNumber else {
            return
        }
        let camera = cameras.first(where: { $0.cameraNumber == cameraNumber })
        itemSelected.onNext(camera)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.collectionView.selectItem(
                at: indexPath,
                animated: false,
                scrollPosition: .top
            )
        }
        
        reloadCameraIfNeeded(row: cameraNumber)
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//        print("MOVE CAMERA", sourceIndexPath.row, destinationIndexPath.row, self.longPressGesture.state.rawValue)
        let item = cameras.remove(at: sourceIndexPath.row)
        cameras.insert(item, at: destinationIndexPath.row)
    }
}

extension OnlinePageViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width - 40, height: 50)
//        return CGSize(width: 36, height: 36)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
//        return 28
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 4
//        return 24
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: 0, bottom: 24, right: 0)
//        return UIEdgeInsets(top: 24, left: 0, bottom: 24, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? CameraNameCell,
              let cameraNumber = cell.cameraNumber else {
            return
        }
        let camera = cameras.first(where: { $0.cameraNumber == cameraNumber })
        itemSelected.onNext(camera)
        reloadCameraIfNeeded(row: cameraNumber)
    }
    
}

extension UICollectionViewFlowLayout {
    
    open override func invalidationContext(forInteractivelyMovingItems targetIndexPaths: [IndexPath], withTargetPosition targetPosition: CGPoint, previousIndexPaths: [IndexPath], previousPosition: CGPoint) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forInteractivelyMovingItems: targetIndexPaths, withTargetPosition: targetPosition, previousIndexPaths: previousIndexPaths, previousPosition: previousPosition)
        
        if let firstPrevious = previousIndexPaths.first, let firstTarget = targetIndexPaths.first, let lastTarget = targetIndexPaths.last, firstPrevious.item != firstTarget.item {
            collectionView?.dataSource?.collectionView?(collectionView!, moveItemAt: firstPrevious, to: lastTarget)
        }
        return context
    }
    
    open override func invalidationContextForEndingInteractiveMovementOfItems(toFinalIndexPaths indexPaths: [IndexPath], previousIndexPaths: [IndexPath], movementCancelled: Bool) -> UICollectionViewLayoutInvalidationContext {
        return super.invalidationContextForEndingInteractiveMovementOfItems(toFinalIndexPaths: indexPaths, previousIndexPaths: previousIndexPaths, movementCancelled: movementCancelled)
    }
    
    open override func layoutAttributesForInteractivelyMovingItem(at indexPath: IndexPath, withTargetPosition position: CGPoint) -> UICollectionViewLayoutAttributes {
        let attributes = super.layoutAttributesForInteractivelyMovingItem(at: indexPath, withTargetPosition: position)
        attributes.alpha = 0.8
        return attributes
    }
}
// swiftlint:enable type_body_length function_body_length line_length file_length
