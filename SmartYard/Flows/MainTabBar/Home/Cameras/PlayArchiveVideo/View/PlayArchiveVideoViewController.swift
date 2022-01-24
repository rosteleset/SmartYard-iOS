//
//  PlayArchiveVideoViewController.swift
//  SmartYard
//
//  Created by admin on 02.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AVKit
import JGProgressHUD
import TouchAreaInsets
import Lottie

// swiftlint:disable:next type_body_length
class PlayArchiveVideoViewController: BaseViewController, LoaderPresentable {
    
    enum Mode {
        case preview
        case edit
    }
    
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    var loader: JGProgressHUD?
    
    @IBOutlet private var mainContainerToVideoLabelConstraint: NSLayoutConstraint!
    @IBOutlet private var mainContainerToAnotherLabelConstraint: NSLayoutConstraint!
    @IBOutlet private var buttonsToCollectionViewConstraint: NSLayoutConstraint!
    
    // MARK: Preview mode
    
    @IBOutlet private weak var previewDateLabel: UILabel!
    
    @IBOutlet private weak var previousSpeedButton: UIButton!
    @IBOutlet private weak var nextSpeedButton: UIButton!
    
    @IBOutlet private weak var periodCollectionView: UICollectionView!
    @IBOutlet private weak var previewButtonsContainer: UIView!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var selectFragmentButton: BlueButton!
    
    @IBOutlet private weak var realVideoContainer: UIView!
    @IBOutlet private weak var progressSlider: SimpleVideoProgressSlider!
    @IBOutlet private weak var fullscreenButton: UIButton!
    @IBOutlet private weak var videoLoadingAnimationView: AnimationView!
    @IBOutlet private var sliderConstraints: [NSLayoutConstraint]!
    
    private var realVideoPlayerViewController: AVPlayerViewController?
    private var realVideoPlayer: AVQueuePlayer?
    
    private var loadingAsset: [AVAsset?] = []
    private var assetArray: [AVAsset] = []
    private var ranges: [(startDate: Date, endDate: Date)] = []    // Доступные периоды

    private var periodicTimeObserver: Any?
    
    private var preferredPlaybackSpeedConfig: ArchiveVideoPlaybackSpeed = .normal {
        didSet {
            guard let player = realVideoPlayer else {
                return
            }
            
            if player.rate != 0 {
                player.rate = preferredPlaybackSpeedConfig.value
            }
            
            previousSpeedButton.isHidden = preferredPlaybackSpeedConfig.previousSpeed == nil
            previousSpeedButton.setTitleForAllStates(preferredPlaybackSpeedConfig.previousSpeed?.title ?? "")
            
            nextSpeedButton.isHidden = preferredPlaybackSpeedConfig.nextSpeed == nil
            nextSpeedButton.setTitleForAllStates(preferredPlaybackSpeedConfig.nextSpeed?.title ?? "")
        }
    }
    
    // MARK: Edit mode
    
    @IBOutlet private weak var editDateLabel: UILabel!
    
    @IBOutlet private weak var shiftTimelineBackwardButton: UIButton!
    @IBOutlet private weak var shiftTimelineForwardButton: UIButton!
    
    @IBOutlet private weak var editButtonsContainer: UIView!
    @IBOutlet private weak var backToPreviewButton: UIButton!
    @IBOutlet private weak var downloadButton: BlueButton!
    
    @IBOutlet private weak var screenshotContainer: UIView!
    @IBOutlet private weak var screenshotImageView: UIImageView!
    @IBOutlet private weak var rangeSlider: SimpleVideoRangeSlider!
    
    private let viewModel: PlayArchiveVideoViewModel
    
    private let periodsProxy = BehaviorSubject<[ArchiveVideoPreviewPeriod]>(value: [])
    private let periodSelectedTrigger = PublishSubject<ArchiveVideoPreviewPeriod?>()
    private let startEndSelectedTrigger = PublishSubject<(Date, Date)>()
    private let screenshotTrigger = PublishSubject<Date>()
    
    private let currentMode = BehaviorSubject<Mode>(value: .preview)
    private let isVideoValid = BehaviorSubject<Bool>(value: false)
    private let isVideoBeingLoaded = BehaviorSubject<Bool>(value: false)
    private let currentPlaybackTime = BehaviorSubject<CMTime>(value: .zero)
    
    private var latestThumbnailConfig: VideoThumbnailConfiguration?
    
    init(viewModel: PlayArchiveVideoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let minViewSize = view.systemLayoutSizeFitting(
            CGSize(width: UIScreen.main.bounds.width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        )
        
        if minViewSize.height > UIScreen.main.bounds.height {
            mainContainerToVideoLabelConstraint.isActive = false
            mainContainerToAnotherLabelConstraint.isActive = false
        }
        
        // Preview mode
        
        configurePeriodPicker()
        configurePlayButton()
        configureSpeedButtons()
        configureSelectFragmentButton()
        configureRealVideoPlayer()
        configureFullscreenButton()
        
        preferredPlaybackSpeedConfig = .normal
        
        // Edit mode

        configureTimelineButtons()
        configureBackToPreviewButton()
        
        // Common
        
        configureSliders()
        configureUIBindings()
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        realVideoPlayerViewController?.view.frame = realVideoContainer.bounds
    }
    
    private func configurePeriodPicker() {
        periodCollectionView.register(nibWithCellClass: VideoPeriodPickerCell.self)
        
        periodCollectionView.dataSource = self
        periodCollectionView.delegate = self
    }
    
    private func configurePlayButton() {
        playButton.configureSelectableButton(
            imageForNormal: UIImage(named: "Play"),
            imageForSelected: UIImage(named: "Pause")
        )
        
        playButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    let newState = !self.playButton.isSelected
                    
                    self.realVideoPlayer?.rate = newState ? self.preferredPlaybackSpeedConfig.value : 0
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureSpeedButtons() {
        previousSpeedButton.setTitleColor(UIColor.SmartYard.gray, for: .normal)
        previousSpeedButton.setTitleColor(UIColor.SmartYard.gray.darken(by: 0.1), for: [.normal, .highlighted])
        
        nextSpeedButton.setTitleColor(UIColor.SmartYard.gray, for: .normal)
        nextSpeedButton.setTitleColor(UIColor.SmartYard.gray.darken(by: 0.1), for: [.normal, .highlighted])
        
        previousSpeedButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self, let previousSpeed = self.preferredPlaybackSpeedConfig.previousSpeed else {
                        return
                    }
                    
                    self.preferredPlaybackSpeedConfig = previousSpeed
                }
            )
            .disposed(by: disposeBag)
        
        nextSpeedButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self, let nextSpeed = self.preferredPlaybackSpeedConfig.nextSpeed else {
                        return
                    }
                    
                    self.preferredPlaybackSpeedConfig = nextSpeed
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureSelectFragmentButton() {
        selectFragmentButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.currentMode.onNext(.edit)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureTimelineButtons() {
        shiftTimelineBackwardButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.rangeSlider.shiftTimelineByValueInSeconds(-900)
                }
            )
            .disposed(by: disposeBag)
        
        shiftTimelineForwardButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.rangeSlider.shiftTimelineByValueInSeconds(900)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureBackToPreviewButton() {
        backToPreviewButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    self.currentMode.onNext(.preview)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configurePeriodicTimeObserver(_ player: AVQueuePlayer) {
        // проверяем, что periodicTimeObserver не был уже создан
        guard self.periodicTimeObserver == nil else {
            return
        }
        
        self.periodicTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] time in

            guard let asset = player.currentItem?.asset else {
                return
             }

            guard let index = self?.assetArray.firstIndex(of: asset) else {
                return
            }
            
            // преобразовываем время полученное от текущего элемента во время от начала выбранного периода
            // ох уж, эти долбаные пропуски в архиве
            let delta = ((self?.ranges[index].startDate.timeIntervalSince1970)!) - (self?.ranges.first!.startDate.timeIntervalSince1970)!

            self?.currentPlaybackTime.onNext(CMTime(seconds: delta, preferredTimescale: CMTimeScale(NSEC_PER_SEC)) + time)
            
        }
    }
    
    private func destroyPeriodicTimeObserver(_ player: AVQueuePlayer) {
        guard let observer = self.periodicTimeObserver else {
            return
        }
        
        player.removeTimeObserver(observer)
        self.periodicTimeObserver = nil
    }
    
    // swiftlint:disable:next function_body_length
    private func configureRealVideoPlayer() {
        let playerViewController = AVPlayerViewController()
        playerViewController.videoGravity = .resizeAspect
        self.realVideoPlayerViewController = playerViewController
        
        let player = AVQueuePlayer()
        playerViewController.player = player
        playerViewController.showsPlaybackControls = false
        self.realVideoPlayer = player
        
        addChild(playerViewController)
        realVideoContainer.insertSubview(playerViewController.view, at: 0)
        playerViewController.didMove(toParent: self)
        
        // MARK: Настройка лоадера
        
        let animation = Animation.named("LoaderAnimation")
        
        videoLoadingAnimationView.animation = animation
        videoLoadingAnimationView.loopMode = .loop
        videoLoadingAnimationView.backgroundBehavior = .pauseAndRestore
        
        // MARK: Когда полноэкранное видео будет закрыто, нужно добавить child controller заново
        
        NotificationCenter.default.rx
            .notification(.archiveFullscreenModeClosed)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self, let playerVc = self.realVideoPlayerViewController else {
                        return
                    }
                    
                    playerVc.showsPlaybackControls = false
                    playerVc.willMove(toParent: nil)
                    playerVc.view.removeFromSuperview()
                    playerVc.removeFromParent()
                    
                    self.addChild(playerVc)
                    self.realVideoContainer.insertSubview(playerVc.view, at: 0)
                    self.realVideoContainer.insertSubview(self.progressSlider, at: 2)
                    playerVc.didMove(toParent: self)
                    // восстановим размеры контейнера с плеером
                    self.realVideoPlayerViewController?.view.frame = self.realVideoContainer.bounds
                    // восстановим отключенные привязки размеров вью слайдера к нашему вью
                    for constraint in self.sliderConstraints {
                        constraint.isActive = true
                    }
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Проверка, валидно ли текущее видео
        
        Driver
            .combineLatest(
                player.rx
                    .observe(AVQueuePlayer.Status.self, "status", options: [.new])
                    .asDriver(onErrorJustReturn: nil),
                player.rx
                    .observe(AVPlayerItem.self, "currentItem", options: [.new])
                    .asDriver(onErrorJustReturn: nil)
            )
            .map { args -> Bool in
                let (status, currentItem) = args
                
                guard status == .readyToPlay,
                    let asset = currentItem?.asset,
                    asset.duration.seconds > 0 else {
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
        
        // MARK: Проверка, воспроизводится ли видео в данный момент
        
        player.rx
            .observe(Float.self, "rate", options: [.new])
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] rate in
                    guard let self = self else {
                        return
                    }
                    
                    self.playButton.isSelected = rate != 0
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Привязка к обновлению текущего времени проигрываемого видео
        
        configurePeriodicTimeObserver(player)
    }
    
    private func configureFullscreenButton() {
        fullscreenButton.setImage(UIImage(named: "Fullscreen"), for: .normal)
        fullscreenButton.setImage(UIImage(named: "Fullscreen")?.darkened(), for: [.normal, .highlighted])
        
        fullscreenButton.touchAreaInsets = UIEdgeInsets(inset: 12)
        
        // MARK: При нажатии на кнопку фуллскрина показываем новый VC с видео на весь экран
        
        fullscreenButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self,
                          let playerVc = self.realVideoPlayerViewController,
                          let progressSlider = self.progressSlider else {
                        return
                    }
                    
                    playerVc.showsPlaybackControls = true
                    playerVc.willMove(toParent: nil)
                    playerVc.view.removeFromSuperview()
                    playerVc.removeFromParent()

                    let fullscreenVc = FullscreenPlayerViewController(
                        playedVideoType: .archive,
                        preferredPlaybackRate: self.preferredPlaybackSpeedConfig.value
                    )
                    
                    fullscreenVc.modalPresentationStyle = .overFullScreen
                    fullscreenVc.modalTransitionStyle = .crossDissolve
                    fullscreenVc.setPlayerViewController(playerVc)
                    // передаём в полноэкранный контроллер вью слайдера и отключаем его привязки от текущего вью
                    fullscreenVc.setProgressSlider(progressSlider)
                    for constraint in self.sliderConstraints {
                        constraint.isActive = false
                    }
                    self.present(fullscreenVc, animated: true)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureSliders() {
        progressSlider.setReferenceCalendar(.moscowCalendar)
        progressSlider.delegate = self
        
        rangeSlider.setReferenceCalendar(.moscowCalendar)
        rangeSlider.delegate = self
    }
    
    // swiftlint:disable:next function_body_length
    private func configureUIBindings() {
        Driver
            .combineLatest(
                currentMode.asDriverOnErrorJustComplete(), isVideoValid.asDriverOnErrorJustComplete()
            )
            .drive(
                onNext: { [weak self] args in
                    guard let self = self else {
                        return
                    }
                    
                    let (mode, isVideoValid) = args
                    
                    self.updateUI(mode: mode, isVideoValid: isVideoValid)
                }
            )
            .disposed(by: disposeBag)
        
        currentPlaybackTime
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] time in
                    self?.progressSlider.setCurrentTime(time)
                }
            )
            .disposed(by: disposeBag)
        
        periodSelectedTrigger
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] period in
                    let startDate: Date? = {
                        guard let period = period else {
                            self?.progressSlider.setVideoDuration(0)
                            self?.ranges = []
                            return nil
                        }
                        
                        self?.progressSlider.setVideoDuration(period.dirtyDuration)
                        self?.ranges = period.ranges
                        
                        return period.startDate
                    }()
                    
                    self?.progressSlider.setRelativeStartDate(startDate)
                }
            )
            .disposed(by: disposeBag)
        
        isVideoBeingLoaded
            .asDriver(onErrorJustReturn: false)
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.videoLoadingAnimationView.isHidden = !isLoading
                    
                    isLoading ? self?.videoLoadingAnimationView.play() : self?.videoLoadingAnimationView.stop()
                    
                    guard !isLoading else {
                        return
                    }
                    
                    // Все видео загрузились
                    
                    DispatchQueue.main.async { [weak self] in
                        
                        guard let self = self else {
                            return
                        }
                        
                        // надо по фактической длине видеофрагментов задать точные ranges в слайдер
                        // и уточнить общую продолжительность видео
                        let exactDurations = self.assetArray.map({ $0.duration.seconds })
                        self.fixDurations(exactDurations)
                        
                        // MARK: Видео готово к просмотру, засовываем его в плеер
                        
                        for asset in self.assetArray {
                            let playerItem = AVPlayerItem(asset: asset)
                            
                            // Необходимо для того, чтобы в HLS потоке мог быть выбран поток с разрешением превышающим разрешение экрана телефона
                            playerItem.preferredMaximumResolution = CGSize(width: 3840, height: 2160)
                            
                            if let realVideoPlayer = self.realVideoPlayer,
                               realVideoPlayer.canInsert(playerItem, after: nil) {
                                realVideoPlayer.insert(playerItem, after: nil)
                            }
                        }
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func updateUI(mode: Mode, isVideoValid: Bool) {
        [
            previousSpeedButton,
            nextSpeedButton,
            selectFragmentButton
        ].forEach {
            $0?.isEnabled = isVideoValid
        }
        
        fullscreenButton.isHidden = mode == .edit || !isVideoValid
        progressSlider.isHidden = mode == .edit || !isVideoValid
        playButton.isEnabled = mode == .preview && isVideoValid
        
        previewButtonsContainer.isHidden = mode == .edit
        selectFragmentButton.isHidden = mode == .edit
        playButton.isHidden = mode == .edit
        realVideoContainer.isHidden = mode == .edit
        periodCollectionView.isHidden = mode == .edit
        previewDateLabel.isHidden = mode == .edit
        
        editButtonsContainer.isHidden = mode == .preview
        shiftTimelineBackwardButton.isHidden = mode == .preview
        shiftTimelineForwardButton.isHidden = mode == .preview
        downloadButton.isHidden = mode == .preview
        backToPreviewButton.isHidden = mode == .preview
        screenshotContainer.isHidden = mode == .preview
        editDateLabel.isHidden = mode == .preview
        
        buttonsToCollectionViewConstraint.isActive = mode == .preview
        
        if mode == .edit {
            realVideoPlayer?.rate = 0
        }
    }

    // swiftlint:disable:next function_body_length
    private func bind() {
        let input = PlayArchiveVideoViewModel.Input(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            downloadTrigger: downloadButton.rx.tap.asDriver(),
            periodSelectedTrigger: periodSelectedTrigger.asDriver(onErrorJustReturn: nil),
            startEndSelectedTrigger: startEndSelectedTrigger.asDriverOnErrorJustComplete(),
            screenshotTrigger: screenshotTrigger.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.date
            .map { date -> String? in
                guard let date = date else {
                    return nil
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yy"
                
                return "Видео от \(dateFormatter.string(from: date))"
            }
            .drive(previewDateLabel.rx.text)
            .disposed(by: disposeBag)
        
        let currentPlaybackTimeDistinctSeconds = currentPlaybackTime
            .asDriverOnErrorJustComplete()
            .map { $0.seconds }
            .distinctUntilChanged { lhs, rhs in
                abs(lhs - rhs) < 0.001
            }
        
        Driver
            .combineLatest(
                output.rangeBounds,
                periodSelectedTrigger.asDriverOnErrorJustComplete(),
                currentPlaybackTimeDistinctSeconds
            )
            .drive(
                onNext: { [weak self] args in
                    guard let self = self else {
                        return
                    }
                    
                    let (rangeBounds, period, playbackTime) = args
                    
                    guard let uPeriod = period else {
                        return
                    }
                    
                    let visibleTimelineEndDate = uPeriod.startDate
                        .addingTimeInterval(playbackTime)
                        .adding(.minute, value: 30)
                    
                    self.rangeSlider.setTimelineConfiguration(
                        visibleTimelineEndDate: visibleTimelineEndDate,
                        lowerBound: rangeBounds?.lower,
                        upperBound: rangeBounds?.upper
                    )
                }
            )
            .disposed(by: disposeBag)
        
        output.videoData
            .do(
                onNext: { [weak self] _ in
                    self?.loadingAsset.forEach({ $0?.cancelLoading() })
                    self?.loadingAsset = []
                    self?.assetArray = []
                }
            )
            .drive(
                onNext: { [weak self] args in
                    // MARK: Сбрасываем видео. У нас возможность пройти дальше привязана к isValid. Нужно инвалидировать
                    guard let self = self,
                            let (urls, thumbnailsConfig) = args else {
                        return
                    }
                    
                    self.realVideoPlayer?.removeAllItems()
                    
                    self.isVideoBeingLoaded.onNext(true)

                    // MARK: Грузим ассеты асинхронно

                    for asset in urls.map({ AVAsset(url: $0) }) {
                    
                        self.loadingAsset.append(asset) // массив для отслеживания хода загрузки ассетов
                        self.assetArray.append(asset) // массив для опредения позиций загружаемых ассетов
                        
                        // MARK: Грузим ключи tracks и duration, т.к. только они сработают для m3u8 потока

                        asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) { [weak self] in
                            guard let self = self else {
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
                                    self.loadingAsset.removeAll(asset) // удаляем asset из списка загружаемых
                                    
                                    if self.loadingAsset.isEmpty {
                                        self.isVideoBeingLoaded.onNext(false)
                                    }
                                    return
                            }
                            
                            guard tracksStatus == .loaded, durationStatus == .loaded else {
                                return
                            }
                            
                            self.loadingAsset.removeAll(asset) // удаляем asset из списка загружаемых
                            
                            if self.loadingAsset.isEmpty {
                                self.isVideoBeingLoaded.onNext(false)
                                
                                DispatchQueue.main.async {
                                
                                    // MARK: Грузим thumbnails
                                    
                                    self.progressSlider.resetThumbnailImages()
                                    self.progressSlider.setActivityIndicatorsHidden(false)

                                    self.rangeSlider.resetThumbnailImages()
                                    self.rangeSlider.setActivityIndicatorsHidden(false)

                                    self.loadThumbnails(
                                        config: thumbnailsConfig,
                                        count: 5,
                                        videoDuration: CMTimeGetSeconds(asset.duration)
                                    )
                                }
                            }
                        }
                    }
                }
            )
            .disposed(by: disposeBag)
        
        Driver
            .combineLatest(
                currentMode.asDriverOnErrorJustComplete(),
                output.screenshotURL
            )
            .filter { args in
                let (mode, _) = args
                
                return mode == .edit
            }
            .map { args -> URL? in
                let (_, url) = args
                
                return url
            }
            .distinctUntilChanged()
            .drive(
                onNext: { [weak self] url in
                    guard let screenshotUrl = url else {
                        return
                    }
                    
                    ScreenshotHelper.generateThumbnailFromVideoUrlAsync(
                        url: screenshotUrl,
                        forTime: .zero
                    ) { cgImage in
                        guard let cgImage = cgImage else {
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self?.screenshotImageView.image = UIImage(cgImage: cgImage)
                        }
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.periodConfiguration
            .drive(
                onNext: { [weak self] in
                    self?.periodsProxy.onNext($0)
                }
            )
            .disposed(by: disposeBag)
        
        periodsProxy
            .subscribe(
                onNext: { [weak self] _ in
                    self?.periodCollectionView.reloadData {
                        self?.selectFirstPeriod()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
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
                    self?.realVideoPlayer?.pause()
                }
            )
            .disposed(by: disposeBag)
        
        // При заходе на окно - запускаем плеер
        
        rx.viewDidAppear
            .asDriver()
            .drive(
                onNext: { [weak self] _ in
                    self?.realVideoPlayer?.play()
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
                    self?.realVideoPlayer?.play()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func selectFirstPeriod() {
        guard periodCollectionView.numberOfItems(inSection: 0) > 0 else {
            return
        }
        
        let indexPath = IndexPath(row: 0, section: 0)
        
        periodCollectionView.selectItem(
            at: indexPath,
            animated: false,
            scrollPosition: .centeredHorizontally
        )
        
        periodCollectionView.delegate?.collectionView?(
            periodCollectionView,
            didSelectItemAt: indexPath
        )
    }
    
    private func loadThumbnails(config: VideoThumbnailConfiguration, count: Int, videoDuration: Double) {
        latestThumbnailConfig = config
        
        config
            .thumbnailUrls(thumbnailsCount: count, actualDuration: videoDuration)
            .enumerated()
            .forEach { offset, url in
                loadThumbnail(
                    index: offset,
                    preferredUrl: url,
                    fallbackUrl: config.fallbackUrl,
                    identifier: config.identifier
                )
            }
    }
    
    private func loadThumbnail(index: Int, preferredUrl: URL, fallbackUrl: URL, identifier: String) {
        ScreenshotHelper.generateThumbnailFromVideoUrlAsync(
            url: preferredUrl,
            forTime: .zero
        ) { [weak self] cgImage in
            guard identifier == self?.latestThumbnailConfig?.identifier else {
                return
            }
            
            guard let cgImage = cgImage else {
                self?.loadFallbackThumbnail(index: index, url: fallbackUrl, identifier: identifier)
                return
            }
            
            DispatchQueue.main.async {
                let uiImage = UIImage(cgImage: cgImage)
                
                self?.progressSlider.setThumbnailImage(uiImage, atIndex: index)
                self?.rangeSlider.setThumbnailImage(uiImage, atIndex: index)
            }
        }
    }
    
    private func loadFallbackThumbnail(index: Int, url: URL, identifier: String) {
        ScreenshotHelper.generateThumbnailFromVideoUrlAsync(
            url: url,
            forTime: .zero
        ) { [weak self] cgImage in
            guard identifier == self?.latestThumbnailConfig?.identifier else {
                return
            }
            
            DispatchQueue.main.async {
                guard let cgImage = cgImage else {
                    self?.progressSlider.setThumbnailImage(nil, atIndex: index)
                    self?.rangeSlider.setThumbnailImage(nil, atIndex: index)
                    
                    return
                }
                
                let uiImage = UIImage(cgImage: cgImage)
                
                self?.progressSlider.setThumbnailImage(uiImage, atIndex: index)
                self?.rangeSlider.setThumbnailImage(uiImage, atIndex: index)
            }
        }
    }
    
    func fixDurations(_ exactDurations: [Float64]) {
        self.ranges = zip(exactDurations, self.ranges).map { duration, old -> (startDate: Date, endDate: Date) in
            let result = (old.startDate, old.startDate.addingTimeInterval(duration))
            return result
        }
        
        let duration = (self.ranges.last?.endDate.timeIntervalSince1970 ?? 0) -
                        (self.ranges.first?.startDate.timeIntervalSince1970 ?? 0)
        
        self.progressSlider.setVideoDuration(duration)
        
    }
}

extension PlayArchiveVideoViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (try? periodsProxy.value())?.count ?? 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let period = (try? periodsProxy.value())?[safe: indexPath.row] else {
            return VideoPeriodPickerCell()
        }
        
        let cell = collectionView.dequeueReusableCell(withClass: VideoPeriodPickerCell.self, for: indexPath)
        
        cell.setTitle(period.title)
        
        return cell
    }
    
}

extension PlayArchiveVideoViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 96, height: 24)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 18
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 18
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let period = (try? periodsProxy.value())?[safe: indexPath.row] else {
            return
        }
        
        periodSelectedTrigger.onNext(period)
    }
    
}

extension PlayArchiveVideoViewController: SimpleVideoProgressSliderDelegate {
    
    func indicatorDidChangePosition(
        videoRangeSlider: SimpleVideoProgressSlider,
        isReceivingGesture: Bool,
        position: Float64
    ) {
        guard !isReceivingGesture else {
            return
        }
        guard realVideoPlayer != nil else {
            return
        }
        
        destroyPeriodicTimeObserver(realVideoPlayer!)
        
        // шаманство с плейлистом
        // получаем объект ассета воспроизведения
        guard let asset = self.realVideoPlayer?.currentItem?.asset else {
            return
         }

        // Получаем номер текущего элемента, какой мы сейчас играем
        guard let currentIndex = self.assetArray.firstIndex(of: asset) else {
            return
        }
        // получим абсолютное время на какое надо спозиционироваться
        let absPosition = self.ranges.first!.startDate.timeIntervalSince1970 + position
        
        // получим номер фрагмента на какой надо спозиционироваться,
        // пропуская все клочки, которые завершились до этой точки
        
        let destIndex = self.ranges.firstIndex { arg0 -> Bool in
            
            let (_ /*startDate*/, endDate) = arg0
            if absPosition > endDate.timeIntervalSince1970 {
                return false
            } else {
                return true
            }
        }
        
        // получим позицию на какую надо перейти внутри элемента плейлиста
        var setPosition = absPosition - self.ranges[destIndex!].startDate.timeIntervalSince1970
        // если попали на дырку в архиве перед элементом, то сдвигаемся на начало элемента следующего за дырой
        setPosition = (setPosition < 0) ? 0 : setPosition
        
        // если мы покидаем текущий элемент, то перезагружаем playlist элементами, начиная с
        if currentIndex != destIndex {
            self.realVideoPlayer?.removeAllItems()
            for asset in self.assetArray.dropFirst(destIndex ?? 0) {
                let playerItem = AVPlayerItem(asset: asset)
                
                // Необходимо для того, чтобы в HLS потоке мог быть выбран поток с разрешением превышающим разрешение экрана телефона
                playerItem.preferredMaximumResolution = CGSize(width: 3840, height: 2160)
                
                if let realVideoPlayer = self.realVideoPlayer,
                   realVideoPlayer.canInsert(playerItem, after: nil) {
                    realVideoPlayer.insert(playerItem, after: nil)
                }
            }
            
        }
        
        realVideoPlayer?.seek(
            to: CMTime(seconds: setPosition, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            toleranceBefore: .zero,
            toleranceAfter: .zero,
            completionHandler: { _ in
                self.configurePeriodicTimeObserver(self.realVideoPlayer!)
            }
        )
    }
    
}

extension PlayArchiveVideoViewController: SimpleVideoRangeSliderDelegate {
    
    func didChangeDate(
        videoRangeSlider: SimpleVideoRangeSlider,
        isReceivingGesture: Bool,
        startDate: Date,
        endDate: Date,
        isLowerBoundReached: Bool,
        isUpperBoundReached: Bool,
        screenshotPolicy: SimpleVideoRangeSlider.ScreenshotPolicy
    ) {
        startEndSelectedTrigger.onNext((startDate, endDate))
        
        shiftTimelineBackwardButton.isEnabled = !isLowerBoundReached
        shiftTimelineForwardButton.isEnabled = !isUpperBoundReached
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.timeZone = Calendar.moscowCalendar.timeZone
        dateFormatter.dateFormat = "dd.MM.yy"
        
        editDateLabel.text = "Видео от \(dateFormatter.string(from: startDate))"
        
        guard !isReceivingGesture else {
            return
        }
        
        switch screenshotPolicy {
        case .start:
            screenshotTrigger.onNext(startDate)
            
        case .end:
            screenshotTrigger.onNext(endDate)
            
        case .middle:
            let diff = endDate.timeIntervalSince(startDate)
            let dateInMiddle = startDate.addingTimeInterval(diff / 2)
            
            screenshotTrigger.onNext(dateInMiddle)
            
        case .none:
            break
        }
    }
    // swiftlint:disable:next file_length
}
