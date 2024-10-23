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
final class PlayArchiveVideoViewController: BaseViewController, LoaderPresentable {
    
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
    @IBOutlet private weak var soundToggleButton: UIButton!
    @IBOutlet private weak var videoLoadingAnimationView: LottieAnimationView!
    @IBOutlet private var sliderConstraints: [NSLayoutConstraint]!
    
    private var realVideoPlayerLayer: AVPlayerLayer?
    private var realVideoPlayer: AVQueuePlayer?
    
    private var loadingAsset: [AVAsset?] = []
    private var assetArray: [AVAsset] = []
    
    // Доступные периоды
    private var ranges: [(startDate: Date, endDate: Date)] = []

    private var periodicTimeObserver: Any?
    
    /// Смещение от начала периода. Требуется только для потоков без разметки времени.
    private var baseTimerShift: Double = 0
    
    private var isInFullscreen = false
    private var hasSound = false
    
    
    private var preferredPlaybackSpeedConfig: ArchiveVideoPlaybackSpeed = .normal {
        didSet {
            guard let player = realVideoPlayer else {
                return
            }
            
            if player.rate != 0 {
                player.rate = preferredPlaybackSpeedConfig.value
                speedTrigger.onNext(preferredPlaybackSpeedConfig)
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
    private let seekToTrigger = PublishSubject<Date>()
    private let speedTrigger = PublishSubject<ArchiveVideoPlaybackSpeed>()

    private let currentMode = BehaviorSubject<Mode>(value: .preview)
    private let isVideoValid = BehaviorSubject<Bool>(value: false)
    private let isVideoBeingLoaded = BehaviorSubject<Bool>(value: false)
    private let isSoundOn = BehaviorSubject<Bool>(value: false)
    private let currentPlaybackTime = BehaviorSubject<CMTime>(value: .zero)
    private var soundStateBeforeFullScreen = false
    
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
        configureSoundToggleButton()
        
        preferredPlaybackSpeedConfig = .normal
        
        // Edit mode

        configureTimelineButtons()
        configureBackToPreviewButton()
        
        // Common
        
        configureSliders()
        configureUIBindings()
        bind()
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
                    guard let self = self,
                          let realVideoPlayer = self.realVideoPlayer else {
                        return
                    }
                    
                    let newState = !self.playButton.isSelected
                    
                    realVideoPlayer.rate = newState ? self.preferredPlaybackSpeedConfig.value : 0
                    if newState {
                        self.speedTrigger.onNext(self.preferredPlaybackSpeedConfig)
                    }
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
    
    private func configureSoundToggleButton() {
        soundToggleButton.setImage(UIImage(named: "SoundOff"), for: .normal)
        soundToggleButton.setImage(UIImage(named: "SoundOn"), for: .selected)
        
        soundToggleButton.touchAreaInsets = UIEdgeInsets(inset: 12)
        
        soundToggleButton.rx.tap
            .withLatestFrom(isSoundOn) { _, isSoundOn in !isSoundOn }
            .bind(to: isSoundOn)
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

            guard let index = self?.assetArray.firstIndex(of: asset),
                  let self = self,
                  !self.ranges.isEmpty else {
                return
            }
            
            // преобразовываем время полученное от текущего элемента во время от начала выбранного периода
            // ох уж, эти долбаные пропуски в архиве
            let delta = ((self.ranges[index].startDate.timeIntervalSince1970)) - (self.ranges.first!.startDate.timeIntervalSince1970)
            self.currentPlaybackTime.onNext(
                CMTime(
                    seconds: delta + self.baseTimerShift,
                    preferredTimescale: CMTimeScale(NSEC_PER_SEC)
                ) + time
            )
            
        }
    }
    override func viewDidLayoutSubviews() {
        if !isInFullscreen {
            realVideoPlayerLayer?.frame = realVideoContainer.bounds
        }
        super.viewDidLayoutSubviews()
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
        let player = AVQueuePlayer()
        player.isMuted = true
        self.realVideoPlayer = player
        
        if realVideoPlayerLayer != nil {
            realVideoPlayerLayer?.removeFromSuperlayer()
        }
        
        realVideoPlayerLayer = AVPlayerLayer(player: player)
        realVideoPlayerLayer?.frame = realVideoContainer.bounds
        realVideoPlayerLayer?.removeAllAnimations()
        realVideoPlayerLayer?.backgroundColor = UIColor.black.cgColor
        realVideoContainer.layer.insertSublayer(realVideoPlayerLayer!, at: 0)
        
        // MARK: Настройка лоадера
        
        let animation = LottieAnimation.named("LoaderAnimation")
        
        videoLoadingAnimationView.animation = animation
        videoLoadingAnimationView.loopMode = .loop
        videoLoadingAnimationView.backgroundBehavior = .pauseAndRestore
        
        // MARK: Когда полноэкранное видео будет закрыто, нужно добавить child controller заново
        
        NotificationCenter.default.rx
            .notification(.archiveFullscreenModeClosed)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self,
                        let playerLayer = self.realVideoPlayerLayer else {
                        return
                    }
                    
                    var shouldTurnOnSound = true
                    do {
                        shouldTurnOnSound = try !(self.isSoundOn.value() || self.realVideoPlayer?.isMuted ?? true)
                    } catch {
                        print("Error getting isSoundOn value: \(error)")
                    }
                    
                    playerLayer.removeFromSuperlayer()
                    self.realVideoContainer.layer.insertSublayer(playerLayer, at: 0)
                    playerLayer.frame = self.realVideoContainer.bounds
                    playerLayer.removeAllAnimations()
                    
                    self.realVideoContainer.insertSubview(self.progressSlider, at: 2)

                    // восстановим отключенные привязки размеров вью слайдера к нашему вью
                    for constraint in self.sliderConstraints {
                        constraint.isActive = true
                    }
                    self.isInFullscreen = false
                    
                    self.isSoundOn.onNext(shouldTurnOnSound)
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
                      asset.duration.isValid else {
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
        
        // MARK: Обработка прыжков по двойному тапу из полноэкранного режима и при смене скоростей
        // (только для seekable==false потоков)
        NotificationCenter.default.rx
            .notification(.videoPlayerSeek)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] arg in
                    guard let self = self,
                          let realVideoPlayer = self.realVideoPlayer,
                          let offset = arg.object as? Int else {
                          return
                    }
                    let newPos = self.ranges.first!.startDate.addingTimeInterval(self.baseTimerShift + Double(offset))
                    self.seekToTrigger.onNext(newPos)
                    self.baseTimerShift = newPos.timeIntervalSince1970 - self.ranges.first!.startDate.timeIntervalSince1970
                    self.configurePeriodicTimeObserver(realVideoPlayer)
                }
            )
            .disposed(by: disposeBag)
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
                          let playerLayer = self.realVideoPlayerLayer,
                          let progressSlider = self.progressSlider else {
                        return
                    }
                    
                    playerLayer.removeFromSuperlayer()
                    
                    var shouldTurnOnSound = false
                    do {
                        shouldTurnOnSound = try self.isSoundOn.value()
                    } catch {
                        print("Error getting isSoundOn value: \(error)")
                    }
                    
                    let fullscreenVc = FullscreenPlayerViewController(
                        playedVideoType: .archive,
                        preferredPlaybackRate: self.preferredPlaybackSpeedConfig.value,
                        hasSound: self.hasSound,
                        isSoundOn: shouldTurnOnSound
                    )
                    
                    fullscreenVc.modalPresentationStyle = .overFullScreen
                    fullscreenVc.modalTransitionStyle = .crossDissolve
                    fullscreenVc.setPlayerLayer(playerLayer)
                    // передаём в полноэкранный контроллер вью слайдера и отключаем его привязки от текущего вью
                    fullscreenVc.setProgressSlider(progressSlider)
                    for constraint in self.sliderConstraints {
                        constraint.isActive = false
                    }
//                    self.isSoundOn.onNext(false)
                    
                    self.isInFullscreen = true
                    self.present(fullscreenVc, animated: true) 
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureSliders() {
        progressSlider.setReferenceCalendar(.serverCalendar)
        progressSlider.delegate = self
        
        rangeSlider.setReferenceCalendar(.serverCalendar)
        rangeSlider.delegate = self
    }
    
    // swiftlint:disable:next function_body_length
    private func configureUIBindings() {
        Driver
            .combineLatest(
                currentMode.asDriverOnErrorJustComplete(),
                isVideoValid.asDriverOnErrorJustComplete(),
                isSoundOn.asDriverOnErrorJustComplete()
            )
            .drive(
                onNext: { [weak self] args in
                    guard let self = self else {
                        return
                    }
                    
                    let (mode, isVideoValid, isSoundOn) = args
                    
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
                    
                    self?.isVideoBeingLoaded.onNext(false)
                    self?.progressSlider.setRelativeStartDate(startDate)
                }
            )
            .disposed(by: disposeBag)
        
        
        isSoundOn
            .asDriver(onErrorJustReturn: false)
            .drive(
                onNext: { [weak self] isSoundOn in
                    self?.soundToggleButton.isSelected = isSoundOn
                    self?.realVideoPlayer?.isMuted = !isSoundOn
                }
            )
            .disposed(by: disposeBag)
        
        isVideoBeingLoaded
            .asDriver(onErrorJustReturn: false)
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    if !(self?.isInFullscreen ?? false) {
                        self?.videoLoadingAnimationView.isHidden = !isLoading
                        isLoading ? self?.videoLoadingAnimationView.play() : self?.videoLoadingAnimationView.stop()
                    }
                    guard !isLoading else {
                        return
                    }
                    
                    // Все видео загрузились
                    
                    DispatchQueue.main.async { [weak self] in
                        
                        guard let self = self,
                              !self.assetArray.isEmpty else {
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
        
        print("Режим: \(mode), видео валидно: \(isVideoValid)")

        
        fullscreenButton.isHidden = mode == .edit || !isVideoValid
        progressSlider.isHidden = mode == .edit // || !isVideoValid
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
            screenshotTrigger: screenshotTrigger.asDriverOnErrorJustComplete(),
            seekToTrigger: seekToTrigger.asDriverOnErrorJustComplete(),
            speedTrigger: speedTrigger.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.date
            .map { date -> String? in
                guard let date = date else {
                    return nil
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yy"
                
                return "\(NSLocalizedString("Video dated", comment: "")) \(dateFormatter.string(from: date))"
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
                periodSelectedTrigger.asDriverOnErrorJustComplete()
            )
            .withLatestFrom(currentPlaybackTimeDistinctSeconds) { ($0.0, $0.1, $1) }
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
        
        output.isVideoLoading
            .drive(
                onNext: { [weak self] videoLoading in
                    self?.videoLoadingAnimationView.isHidden = !videoLoading
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
                    self.isVideoBeingLoaded.onNext(true)
                    
                    self.realVideoPlayer?.removeAllItems()
                    
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
                                    guard let thumbnailsConfig = thumbnailsConfig else {
                                        // если нет thumbnailsConfig, то значит надо было просто заменить видеопоток
                                        return
                                    }
                                    self.baseTimerShift = 0
                                    
                                    self.progressSlider.resetThumbnailImages()
                                    self.progressSlider.setActivityIndicatorsHidden(false)

                                    self.rangeSlider.resetThumbnailImages()
                                    self.rangeSlider.setActivityIndicatorsHidden(false)
                                    
                                    let startDate = self.ranges.first?.startDate.timeIntervalSince1970
                                    let endDate = self.ranges.last?.endDate.timeIntervalSince1970
                                    
                                    var rangesDuration = 3.0 * 60.0 * 60.0
                                    
                                    if let startDate = startDate, let endDate = endDate {
                                        rangesDuration = endDate - startDate
                                    }
                                    
                                    let rangesDurationTime = CMTimeMakeWithSeconds(
                                        rangesDuration,
                                        preferredTimescale: 1
                                    )
                                    
                                    let duration = asset.duration.isIndefinite ? rangesDurationTime : asset.duration
                                    
                                    self.loadThumbnails(
                                        config: thumbnailsConfig,
                                        count: 5,
                                        videoDuration: CMTimeGetSeconds(duration)
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
            .map { args -> (url: URL?, imageType: SYImageType) in
                let (_, (url, imageType)) = args
                
                return (url, imageType)
            }
            .distinctUntilChanged { $0.url == $1.url }
            .drive(
                onNext: { [weak self] args in
                    let (screenshotUrl, imageType) = args
                    
                    guard let screenshotUrl = screenshotUrl else {
                        return
                    }
                    
                    ScreenshotHelper.generateThumbnailFromVideoUrlAsync(
                        url: screenshotUrl,
                        forTime: .zero,
                        imageType: imageType
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
        
        output.hasSound
            .drive(onNext: { [weak self] hasSound in
                DispatchQueue.main.async {
                    self?.soundToggleButton.isHidden = !hasSound
                    self?.hasSound = hasSound
                }
            })
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
                    identifier: config.identifier,
                    imageType: config.camera.screenshotsType
                )
            }
    }
    
    private func loadThumbnail(index: Int, preferredUrl: URL, fallbackUrl: URL, identifier: String, imageType: SYImageType) {
        ScreenshotHelper.generateThumbnailFromVideoUrlAsync(
            url: preferredUrl,
            forTime: .zero,
            imageType: imageType
        ) { [weak self] cgImage in
            guard identifier == self?.latestThumbnailConfig?.identifier else {
                return
            }
            
            guard let cgImage = cgImage else {
                self?.loadFallbackThumbnail(index: index, url: fallbackUrl, identifier: identifier, imageType: imageType)
                return
            }
            
            DispatchQueue.main.async {
                let uiImage = UIImage(cgImage: cgImage)
                
                self?.progressSlider.setThumbnailImage(uiImage, atIndex: index)
                self?.rangeSlider.setThumbnailImage(uiImage, atIndex: index)
            }
        }
    }
    
    private func loadFallbackThumbnail(index: Int, url: URL, identifier: String, imageType: SYImageType) {
        ScreenshotHelper.generateThumbnailFromVideoUrlAsync(
            url: url,
            forTime: .zero,
            imageType: imageType
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
        // отдельно обрабатываем ситуацию, когда в массиве assets есть только один элемент и
        // длительность его неизвестна.
        guard exactDurations.count > 1,
              let element = exactDurations.first,
              !element.isNaN else {
            
            let duration = (self.ranges.last?.endDate.timeIntervalSince1970 ?? 0) -
                            (self.ranges.first?.startDate.timeIntervalSince1970 ?? 0)
            
            self.progressSlider.setVideoDuration(duration)
            return
        }
        
        self.ranges = zip(exactDurations, self.ranges).map { duration, old -> (startDate: Date, endDate: Date) in
            let result = duration.isNaN ? old : (old.startDate, old.startDate.addingTimeInterval(duration))
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
        guard let realVideoPlayer = realVideoPlayer else {
            return
        }
        
        destroyPeriodicTimeObserver(realVideoPlayer)
        
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
        
        let asset = self.realVideoPlayer?.currentItem?.asset
        
        // для потоков, которые не умеют перематывать поток и не ориентируются во времени, приходится делать
        // запаснй вариант для реализации перемотки через перезапуск потока с нового места.
        if asset?.duration.isIndefinite ?? true {
            let newPos = self.ranges[destIndex!].startDate.addingTimeInterval(setPosition)
            self.seekToTrigger.onNext(newPos)
            self.baseTimerShift = newPos.timeIntervalSince1970 - self.ranges.first!.startDate.timeIntervalSince1970
            self.configurePeriodicTimeObserver(realVideoPlayer)
            return
        }
        
        // шаманство с плейлистом
        // получаем объект ассета воспроизведения
        guard let asset = asset else {
            return
         }

        // Получаем номер текущего элемента, какой мы сейчас играем
        guard let currentIndex = self.assetArray.firstIndex(of: asset) else {
            return
        }
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
        
        realVideoPlayer.seek(
            to: CMTime(seconds: setPosition, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            toleranceBefore: .zero,
            toleranceAfter: .zero,
            completionHandler: { [weak self] _ in
                guard let self = self,
                let realVideoPlayer = self.realVideoPlayer else { return }
                self.configurePeriodicTimeObserver(realVideoPlayer)
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
        
        dateFormatter.timeZone = Calendar.serverCalendar.timeZone
        dateFormatter.dateFormat = "dd.MM.yy"
        
        editDateLabel.text = "\(NSLocalizedString("Video dated", comment: "")) \(dateFormatter.string(from: startDate))"
        
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
