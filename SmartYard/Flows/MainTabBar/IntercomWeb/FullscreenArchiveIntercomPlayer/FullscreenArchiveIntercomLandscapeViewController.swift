//
//  FullscreenArchiveIntercomLandscapeViewController.swift
//  SmartYard
//
//  Created by devcentra on 20.11.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length cyclomatic_complexity type_body_length file_length closure_body_length

import UIKit
import AVKit
import RxSwift
import RxCocoa
import JGProgressHUD
import Lottie
import RxDataSources

class FullscreenArchiveIntercomLandscapeViewController: UIViewController, LoaderPresentable {
    
    private let preferredPlaybackRate: Float = 1
    private var doors: [DoorExtendedObject] = []
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var zoomContentView: UIView!
    @IBOutlet private weak var videoView: UIView!
    @IBOutlet private weak var videoOnlineView: UIView!
    @IBOutlet private weak var videoArchiveView: UIView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var exitFullscreenButton: UIButton!
    @IBOutlet private weak var onlineButtonsStack: UIStackView!
    @IBOutlet private weak var muteButton: UIButton!
    @IBOutlet private weak var openDoor1Button: UIButton!
    @IBOutlet private weak var openDoor2Button: UIButton!
    @IBOutlet private weak var openDoor3Button: UIButton!
    @IBOutlet private weak var playTimeView: UIView!
    @IBOutlet private weak var goLiveButton: UIButton!
    @IBOutlet private weak var liveViewButton: UIButton!

    @IBOutlet private weak var timelineView: UIView!
    @IBOutlet private weak var archiveCollectionView: UICollectionView!
    @IBOutlet private weak var videoLoadingAnimationView: LottieAnimationView!
    @IBOutlet private weak var archiveImageView: UIView!
    @IBOutlet private weak var archiveImageViewImage: UIImageView!
    @IBOutlet private weak var archiveImageNotFound: UIImageView!

    private var player: AVPlayer?
    private weak var playerLayer: AVPlayerLayer?
    private var loadingAsset: AVAsset?
    private let isVideoValid = BehaviorSubject<Bool>(value: false)
    private let isVideoBeingLoaded = BehaviorSubject<Bool>(value: false)
    private let isVideoMuted = BehaviorSubject<Bool>(value: true)
    private let isArchiveScrolling = BehaviorSubject<Bool>(value: false)
    private let zoomIndex = BehaviorSubject<CGFloat>(value: 1.0)
    private var playerArchive: AVPlayer?
    private weak var playerArchiveLayer: AVPlayerLayer?
    private var loadingArchiveAsset: AVAsset?
    private let isVideoArchiveValid = BehaviorSubject<Bool>(value: false)
    private var needOnineReload = false
    private var isScrollToDate = false

    var deltaTimeInterval: Int = 60
    var fullSectionCount: Int = 24 * 60
    var archiveItemHeight: CGFloat = 5.0
    
    private let dateArchiveUpdate = BehaviorSubject<Date?>(value: nil)
    private let dateArchiveUpper = BehaviorSubject<Date>(value: Date())
    private let dateThumbGenerated = BehaviorSubject<Date?>(value: nil)

    private var selectedCamera: CameraExtendedObject?
    private var selectedCameraNumber: Int?
    private var doorsbutton: [UIButton] = []
    private var events: [APIPlog] = []
    private var eventsdiff: [Double] = []
    private var thumbLoadingQueue: [(day: Date, url: URL)] = []
    private let previewCache = NSCache<NSString, UIImage>()
    private var selectedCameraOnline: Bool = false

    var upperDateLimit = Date()
    var lowerDateLimit = Date()
    private var loadedOnlineVideoDate: Date?
    private var loadedArchiveVideoDate: Date?
    private var timeSecondsArchiveVideo: CGFloat?
    private var positionYArchiveVideo: CGFloat?
    var ranges: [APIArchiveRange?] = []
    private let loweUpperSelectedTrigger = PublishSubject<(Date?, Date?)>()
    private var timer: Timer?
    private var landscapeOrientation: Bool = false

    var loader: JGProgressHUD?
    let selectCameraTrigger = PublishSubject<CameraExtendedObject>()
    let updateRangesForCameraTrigger = PublishSubject<CameraExtendedObject?>()

    fileprivate let viewModel: FullscreenArchiveIntercomPlayerViewModel
    
    private var disposeBag = DisposeBag()
    
    init(viewModel: FullscreenArchiveIntercomPlayerViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
        
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoView.bounds
        playerLayer?.videoGravity = .resizeAspect
        playerArchiveLayer?.frame = videoView.bounds
        playerArchiveLayer?.videoGravity = .resizeAspect
        archiveImageViewImage.frame = archiveImageView.bounds
        
        self.view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIViewController.attemptRotationToDeviceOrientation()
        
        if self.timer == nil {
            self.showControls()
            self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: onTimer)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        landscapeOrientation = [.landscapeLeft, .landscapeRight].contains(UIDevice.current.orientation)
        if UIDevice.current.orientation == .unknown {
            landscapeOrientation = [.landscapeLeft, .landscapeRight].contains(UIApplication.shared.statusBarOrientation)
        }
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard isBeingDismissed else {
            return
        }

        if let player = playerLayer {
            player.player?.pause()
        }
        if let player = playerArchiveLayer {
            player.player?.pause()
        }

    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        DispatchQueue.main.async {
            if size.height < size.width {
                self.scrollView.zoomScale = 1.0
                self.scrollView.contentSize = size
                self.archiveImageView.frame = self.zoomContentView.bounds
                self.videoView.frame = self.zoomContentView.bounds
                self.archiveImageViewImage.frame = self.zoomContentView.bounds
                self.playerLayer?.frame = self.zoomContentView.bounds
                self.playerLayer?.videoGravity = .resizeAspect
                self.playerArchiveLayer?.frame = self.zoomContentView.bounds
                self.playerArchiveLayer?.videoGravity = .resizeAspect
                
                if let timer = self.timer, timer.isValid {
                    timer.invalidate()
                }
                self.showControls()
                self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: self.onTimer)
                self.landscapeOrientation = true
                self.isArchiveScrolling.onNext(false)
            } else {
                self.landscapeOrientation = false
                self.player?.pause()
                self.playerArchive?.pause()
            }
        }
    }
    
    override open var shouldAutorotate: Bool {
        return true
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.landscapeRight, .landscapeLeft]
    }
    
    @IBAction private func tapView(_ sender: UITapGestureRecognizer) {
        
        guard let timer = self.timer,
              timer.isValid else {
            self.showControls()
            self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: onTimer)
            return
        }
        
        timer.invalidate()
        self.timer = nil
        self.hideControls()
        
    }
    
    @IBAction private func tapOnlineButton() {
        let maxRangeDate = ranges.compactMap { $0?.endDate }.max() ?? upperDateLimit
        if upperDateLimit < maxRangeDate {
            upperDateLimit = maxRangeDate
            loweUpperSelectedTrigger.onNext((lowerDateLimit, upperDateLimit))
        }
        playerArchive?.pause()
        dateArchiveUpper.onNext(maxRangeDate)
        archiveCollectionView.setContentOffset(CGPoint(x: 0, y: -49), animated: true)
    }

    @IBAction private func tapPortraitView() {
        NotificationCenter.default.post(name: .fullscreenArchiveForcePortrait, object: nil)
    }

    func onTimer(_: Timer) {
        if let timer = self.timer,
           timer.isValid {
            timer.invalidate()
        }
        self.timer = nil
        self.hideControls()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePlayer()
        configurePlayerArchive()
        configureTimelineView()
//        configureSwipe()
        bind()
    }

    private func configurePlayer() {
        
        doorsbutton = [
            openDoor1Button,
            openDoor2Button,
            openDoor3Button
        ]
        doorsbutton.map {
            $0.isHidden = true
        }
        
        let player = AVPlayer()
        self.player = player
        
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
        }
        
        playerLayer = AVPlayerLayer(player: player)
        videoOnlineView.layer.insertSublayer(playerLayer!, at: 0)
        playerLayer?.removeAllAnimations()
        playerLayer?.backgroundColor = UIColor.black.cgColor
        
        if let isMuted = try? isVideoMuted.value() {
            playerLayer?.player?.isMuted = isMuted
        } else {
            muteButton.setImage(UIImage(named: "volumeOff"), for: .normal)
            muteButton.setImage(UIImage(named: "volumeOff")?.darkened(), for: [.normal, .highlighted])
            playerLayer?.player?.isMuted = true
        }

        setPlayerLayer(playerLayer!)
        
        // MARK: Настройка лоадера
        let animation = LottieAnimation.named("LoaderAnimation")
        
        videoLoadingAnimationView.animation = animation
        videoLoadingAnimationView.loopMode = .loop
        videoLoadingAnimationView.backgroundBehavior = .pauseAndRestore
        
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
        
        self.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(2, preferredTimescale: 1), queue: DispatchQueue.main) { [weak self] time in
            guard let self = self,
                  let player = self.player,
                  let item = player.currentItem,
                  item.status == .readyToPlay,
                  player.rate != 0 else {
                return
            }
            self.isVideoBeingLoaded.onNext(false)

            let currentTime = CMTimeGetSeconds(player.currentTime())
            
            guard let dateonline = self.loadedOnlineVideoDate,
                  let date = Calendar.novokuznetskCalendar.date(byAdding: .second, value: Int(currentTime), to: dateonline) else {
                return
            }
            if self.archiveCollectionView.isDragging || self.archiveCollectionView.isDecelerating {
                return
            }
            
            let upperDateLimitTime = self.upperDateLimit.unixTimestamp.int
            self.upperDateLimit = Date()
            
            if let maxRange = self.ranges.enumerated().max(by: { (a, b) in a.element!.from < b.element!.from }) {
                self.ranges[maxRange.offset]?.duration += Double(self.upperDateLimit.unixTimestamp.int - upperDateLimitTime)
            }
//            print("ONLINE", currentTime, date)
            self.loweUpperSelectedTrigger.onNext((self.lowerDateLimit, self.upperDateLimit))
            self.archiveCollectionView.reloadData()
        }
    }
    
    func setPlayerLayer(_ playerLayer: AVPlayerLayer) {
        
        self.playerLayer = playerLayer
        
        guard let player = playerLayer.player else {
            return
        }
        
        player.rx
            .observe(Float.self, "rate", options: [.new])
            .observe(on: MainScheduler.asyncInstance)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] rate in
                    guard let self = self else {
                        return
                    }
                    
                    // MARK: Если мы нажимаем на стандартную кнопку Play, то воспроизведение будет со скоростью 1x
                    // Нам нужно, чтобы видео воспроизводилось с заданной скоростью
                    // Поэтому отслеживаем изменения, если вдруг rate стал равен 1 - меняем его на preferred
                    
                    if rate == 1, self.preferredPlaybackRate != 1 {
                        self.playerLayer?.player?.rate = self.preferredPlaybackRate
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configurePlayerArchive() {
        
        let player = AVPlayer()
        self.playerArchive = player
        
        if playerArchiveLayer != nil {
            playerArchiveLayer?.removeFromSuperlayer()
        }
        
        playerArchiveLayer = AVPlayerLayer(player: player)
        videoArchiveView.layer.insertSublayer(playerArchiveLayer!, at: 0)
        playerArchiveLayer?.removeAllAnimations()
        playerArchiveLayer?.backgroundColor = UIColor.black.cgColor
        
        if let isMuted = try? isVideoMuted.value() {
            playerArchiveLayer?.player?.isMuted = isMuted
        } else {
            playerArchiveLayer?.player?.isMuted = true
        }

        setPlayerArchiveLayer(playerArchiveLayer!)
        
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
                onNext: { [weak self] isVideoArchiveValid in
                    self?.isVideoArchiveValid.onNext(isVideoArchiveValid)
                }
            )
            .disposed(by: disposeBag)
        
        self.playerArchive?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { [weak self] time in
            guard let self = self else {return}
            guard let player = self.playerArchive,
                  let item = player.currentItem,
                  item.status == .readyToPlay,
                  player.rate != 0 else {
                return
            }
            self.isVideoBeingLoaded.onNext(false)

            if (self.archiveCollectionView.isDragging || self.archiveCollectionView.isDecelerating) {
                player.pause()
                return
            }
            
            let calendar = Calendar.novokuznetskCalendar
            let currentTime = CMTimeGetSeconds(player.currentTime())

            guard let datearchive = self.loadedArchiveVideoDate,
                  let date = calendar.date(byAdding: .second, value: Int(currentTime), to: datearchive),
                  let maxRangeDate = self.ranges.compactMap { $0?.endDate }.max(),
                  date < maxRangeDate else {
                player.pause()
                return
            }
            
//            let timestamp = date.unixTimestamp.int
            let archived = self.ranges.filter {
                guard let range = $0 else { return false }
                return (range.startDate <= date) && (range.endDate > date)
            }
            if archived.isEmpty {
                print("PAUSED")
                player.pause()
                return
            }

            let interval = currentTime - (self.timeSecondsArchiveVideo ?? 0)
            self.timeSecondsArchiveVideo = currentTime
            
            if let isVideoValid = try? self.isVideoValid.value(),
               isVideoValid {
                if let maxRange = self.ranges.enumerated().max(by: { (a, b) in a.element!.from < b.element!.from }) {
                    self.ranges[maxRange.offset]?.duration += interval
                }
            }
            
            let formatterOnline = DateFormatter()
            formatterOnline.dateFormat = "HH:mm:ss"
            formatterOnline.timeZone = calendar.timeZone
            formatterOnline.locale = calendar.locale

            let formatterCalendar = DateFormatter()
            formatterCalendar.dateFormat = "dd.MM"
            formatterCalendar.timeZone = calendar.timeZone
            formatterCalendar.locale = calendar.locale
            
            self.goLiveButton.setTitle(formatterOnline.string(from: date), for: .normal)
            
            self.archiveCollectionView.contentOffset.y = (self.positionYArchiveVideo ?? 0) - currentTime / CGFloat(self.deltaTimeInterval) * self.archiveItemHeight
//            print("PLAYER", currentTime, self.archiveCollectionView.contentOffset.y)
            self.archiveCollectionView.reloadData()
        }
    }
    
    func setPlayerArchiveLayer(_ playerLayer: AVPlayerLayer) {
        
        self.playerArchiveLayer = playerLayer
        
        guard let player = playerLayer.player else {
            return
        }
        
        player.rx
            .observe(Float.self, "rate", options: [.new])
            .observe(on: MainScheduler.asyncInstance)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] rate in
                    guard let self = self else {
                        return
                    }
                    
                    // MARK: Если мы нажимаем на стандартную кнопку Play, то воспроизведение будет со скоростью 1x
                    // Нам нужно, чтобы видео воспроизводилось с заданной скоростью
                    // Поэтому отслеживаем изменения, если вдруг rate стал равен 1 - меняем его на preferred
                    
                    if rate == 1, self.preferredPlaybackRate != 1 {
                        self.playerArchiveLayer?.player?.rate = self.preferredPlaybackRate
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureTimelineView() {
        archiveCollectionView.delegate = self
        archiveCollectionView.dataSource = self
        archiveCollectionView.register(nibWithCellClass: TimelineLandscapeSectionCell.self)
        archiveCollectionView.isPagingEnabled = false
        archiveCollectionView.contentInset = UIEdgeInsets(top: 49, left: 0, bottom: 40, right: 0)
        
        liveViewButton.isHidden = true
        playTimeView.isHidden = true
        goLiveButton.isHidden = true
    }
    
    private func bind() {
        
        isVideoBeingLoaded
            .asDriver(onErrorJustReturn: false)
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    guard let self = self else {
                        return
                    }
                    self.videoLoadingAnimationView.isHidden = !isLoading
                    if isLoading {
                        self.videoLoadingAnimationView.play()
                    } else {
                        self.videoLoadingAnimationView.stop()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        isVideoValid
            .asDriver(onErrorJustReturn: false)
            .drive(
                onNext: { [weak self] isVideoValid in
                    guard let self = self else {
                        return
                    }
                    if isVideoValid {
                        self.upperDateLimit = Date()
                        self.loweUpperSelectedTrigger.onNext((self.lowerDateLimit, self.upperDateLimit))
                        self.archiveCollectionView.reloadData()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        Driver
            .combineLatest(
                isArchiveScrolling.asDriver(onErrorJustReturn: false),
                dateArchiveUpper.asDriverOnErrorJustComplete()
            )
            .distinctUntilChanged { $0 == $1 }
            .drive(
                onNext: { [weak self] args in
                    let (isArchiveScrolling, datearchive) = args
                    
                    guard let self = self,
                          self.landscapeOrientation,
                          let camera = self.selectedCamera else {
                        return
                    }

                    let calendar = Calendar.novokuznetskCalendar
                    let formatterOnline = DateFormatter()
                    formatterOnline.dateFormat = "HH:mm:ss"
                    formatterOnline.timeZone = calendar.timeZone
                    formatterOnline.locale = calendar.locale
                    
                    let formatterCalendar = DateFormatter()
                    formatterCalendar.dateFormat = "dd.MM"
                    formatterCalendar.timeZone = calendar.timeZone
                    formatterCalendar.locale = calendar.locale

                    self.goLiveButton.isHidden = false
                    self.playTimeView.isHidden = false
                    
                    let maxRangeDate = self.ranges.compactMap { $0?.endDate }.max() ?? self.upperDateLimit
                    
//                    print("MAXRANGE", maxRangeDate, datearchive)
                    if let dateonline = calendar.date(byAdding: .second, value: self.deltaTimeInterval * -3, to: maxRangeDate),  datearchive > dateonline,
                       self.selectedCameraOnline, !self.isScrollToDate {
                        let interval = maxRangeDate.timeIntervalSince(datearchive)
                        if let playerarchiverate = self.playerArchive?.rate,
                           playerarchiverate > 0,
                           interval > Double(self.deltaTimeInterval), interval < Double(3 * self.deltaTimeInterval) {
                            print(interval)
                            return
                        }
                        self.playerArchive?.pause()
                        self.goLiveButton.setTitle("ОНЛАЙН", for: .normal)
                        self.archiveImageView.isHidden = true
                        self.videoView.isHidden = false
                        self.videoArchiveView.isHidden = true
                        self.videoOnlineView.isHidden = false
                        self.liveViewButton.isHidden = true
                        self.thumbLoadingQueue = []
                        let resultingString = camera.video + "/index.m3u8" + "?token=\(camera.token)"
                        
                        guard let url = URL(string: resultingString) else {
                            return
                        }
                        guard self.needOnineReload, !isArchiveScrolling else {
                            if let playerrate = self.player?.rate, playerrate == 0 {
                                self.needOnineReload = false
                                self.updateRangesForCameraTrigger.onNext(self.selectedCamera)
                                print("Replay online on stop \(url)")
                                self.loadVideoOnline(url)
                            }
                            return
                        }
                        self.needOnineReload = false
                        self.updateRangesForCameraTrigger.onNext(self.selectedCamera)
                        print("Play online from \(url)")
                        self.loadVideoOnline(url)
                        return
                    }
                    let archived = self.ranges.filter {
                        guard let range = $0 else { return false }
                        return (range.startDate <= datearchive) && (range.endDate > datearchive)
                    }
                    if archived.isEmpty {
                        self.goLiveButton.setTitle(formatterOnline.string(from: datearchive), for: .normal)
                        
                        self.player?.pause()
                        self.playerArchive?.pause()
                        self.videoView.isHidden = true
                        self.archiveImageView.isHidden = false
                        self.archiveImageViewImage.isHidden = true
                        self.archiveImageNotFound.isHidden = false
                        return
                    }
                    
                    if self.playerArchive?.rate != 0,
                       !self.archiveCollectionView.isDragging,
                       !self.archiveCollectionView.isDecelerating {
//                        print("RELOAD NOT ACTIVE")
                        return
                    }
                    let correction = 0
//                    let correction = maxRangeDate.timeIntervalSince(self.upperDateLimit).int
                    guard let activedate = calendar.date(byAdding: .second, value: correction, to: datearchive) else {
                        return
                    }
//                    print("CORRECTION", correction, activedate)
                    let timestamp = activedate.unixTimestamp.int
                    self.goLiveButton.setTitle(formatterOnline.string(from: activedate), for: .normal)
                    
                    self.archiveImageNotFound.isHidden = true
                    self.archiveImageViewImage.isHidden = false
                    self.videoView.isHidden = true
                    self.archiveImageView.isHidden = false
                    if self.selectedCameraOnline {
                        self.liveViewButton.isHidden = false
                    }
                    if (self.isScrollToDate) {
                        self.isScrollToDate = false
                        return
                    }
                    if isArchiveScrolling {
                        self.needOnineReload = true
                        self.player?.pause()
                        self.playerArchive?.pause()
                        if let datethumb = try? self.dateThumbGenerated.value(),
                           abs(activedate.timeIntervalSince(datethumb)) < Double(self.deltaTimeInterval) {
                            return
                        }
                        
                        let preview = camera.video +
                        "/\(timestamp)-preview.mp4?token=\(camera.token)"
                        
                        guard let screenshotUrl = URL(string: preview) else {
                            return
                        }
                        self.thumbLoadingQueue.append( (day: activedate, url: screenshotUrl) )
                        
                        self.generateThumb(activedate)
                    } else {
                        self.player?.pause()
                        let resultingString = camera.video + "/index-\(timestamp)-86400.m3u8?token=\(camera.token)"

                        guard let url = URL(string: resultingString) else {
                            return
                        }
                        self.loadedArchiveVideoDate = activedate
                        self.loadVideoArchive(url)
                    }
                }
            )
            .disposed(by: disposeBag)

        let input = FullscreenArchiveIntercomPlayerViewModel.InputLandscape(
            updateRangesTrigger: updateRangesForCameraTrigger.asDriver(onErrorJustReturn: nil),
            dateArchiveTrigger: dateArchiveUpper.asDriverOnErrorJustComplete(),
            lowerUpperSelectedTrigger: loweUpperSelectedTrigger.asDriverOnErrorJustComplete(),
            buttons: doorsbutton,
            backTrigger: backButton.rx.tap.asDriver(),
            muteTrigger: muteButton.rx.tap.asDriver()
        )
        
        let output = viewModel.transformLandscape(input)
        
        output.selectedCamera
            .drive(
                onNext: { [weak self] camera in
                    guard let self = self, let camera = camera else {
                        return
                    }
                    self.selectedCamera = camera
                }
            )
            .disposed(by: disposeBag)
        
        output.selectedCameraStatus
            .drive(
                onNext: { [weak self] status in
                    guard let self = self, let status = status else {
                        self?.selectedCameraOnline = false
                        self?.videoOnlineView.isHidden = true
                        return
                    }
                    self.selectedCameraOnline = status
                    self.videoOnlineView.isHidden = !status
                    if status, let camera = self.selectedCamera {
                        self.loadCamera()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.isVideoMutted
            .drive(
                onNext: { [weak self] isVideoMuted in
                    self?.player?.isMuted = isVideoMuted
                    self?.isVideoMuted.onNext(isVideoMuted)
                    if isVideoMuted {
                        self?.muteButton.setImage(UIImage(named: "volumeOff"), for: .normal)
                        self?.muteButton.setImage(UIImage(named: "volumeOff")?.darkened(), for: [.normal, .highlighted])
                    } else {
                        self?.muteButton.setImage(UIImage(named: "volumeOn"), for: .normal)
                        self?.muteButton.setImage(UIImage(named: "volumeOn")?.darkened(), for: [.normal, .highlighted])
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.lowerUpperDates
            .distinctUntilChanged { $0 == $1 }
            .drive(
                onNext: { [weak self] dates in
                    let (lowerdate, upperdate) = dates
                    guard let self = self, let lowerdate = lowerdate, let upperdate = upperdate else {
                        return
                    }
                    self.upperDateLimit = upperdate
                    self.lowerDateLimit = lowerdate
                    self.archiveCollectionView.reloadData()
//                    if let date = self.reCalcTimelinePosition(true) {
//                        self.dateArchiveUpper.onNext(date)
//                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.rangesForCurrentCamera
            .drive(
                onNext: { [weak self] ranges in
                    guard let self = self else {
                        return
                    }
                    guard let ranges = ranges, !ranges.isEmpty else {
                        self.ranges = []
                        self.reloadTimeLineIfNeeded(refreshTop: true)
                        return
                    }
                    self.ranges = ranges
                    self.reloadTimeLineIfNeeded(refreshTop: true)
                }
            )
            .disposed(by: disposeBag)
        
        output.events
            .drive(
                onNext: { [weak self] events in
                    self?.updateEvents(events)
                }
            )
            .disposed(by: disposeBag)
        
        output.selectedDate
            .distinctUntilChanged()
            .drive(
                onNext: { [weak self] date in
                    guard let self = self,
                          !self.landscapeOrientation else {
                        return
                    }
                    self.scrollToDate(date)
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
                    guard let self = self else {
                        return
                    }
                    if let isVideo = try? self.isVideoValid.value(),
                       isVideo {
                        self.player?.pause()
                        self.playerArchive?.pause()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        // При заходе на окно - запускаем плеер
        
        rx.viewDidAppear
            .asDriver()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    self.isArchiveScrolling.onNext(false)
                }
            )
            .disposed(by: disposeBag)
        
//        NotificationCenter.default.rx
//            .notification(UIDevice.orientationDidChangeNotification)
//            .asDriverOnErrorJustComplete()
//            .drive(
//                onNext: { [weak self] _ in
//                    if UIDevice.current.orientation == .portrait {
//                        self?.playVideo(false)
//                    }
//                }
//            )
//            .disposed(by: disposeBag)
        
        // При разворачивании приложения (если окно открыто) - запускаем плеер
        
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(rx.isVisible.asDriverOnErrorJustComplete())
            .isTrue()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    self.isArchiveScrolling.onNext(false)
                }
            )
            .disposed(by: disposeBag)
        
//        if let playerLayer = playerLayer {
//            videoView.layer.insertSublayer(playerLayer, at: 0)
//        }
    }
    
    private func reloadTimeLineIfNeeded(refreshTop: Bool = false) {
        
        if refreshTop {
            archiveCollectionView.setContentOffset(CGPoint(x: 0, y: -49), animated: false)
        }
        archiveCollectionView.reloadData()
    }
    
    private func loadVideoArchive(_ url: URL) {
        print("Play archive from #\(url)")

        playerArchive?.replaceCurrentItem(with: nil)
        
        if let isMuted = try? isVideoMuted.value() {
            playerArchiveLayer?.player?.isMuted = isMuted
        } else {
            muteButton.setImage(UIImage(named: "volumeOff"), for: .normal)
            muteButton.setImage(UIImage(named: "volumeOff")?.darkened(), for: [.normal, .highlighted])
            playerArchiveLayer?.player?.isMuted = true
        }
        
        loadingAsset?.cancelLoading()
        loadingAsset = nil
        timeSecondsArchiveVideo = nil
        positionYArchiveVideo = archiveCollectionView.contentOffset.y
        
        let asset = AVAsset(url: url)
        
        loadingAsset = asset
        
        isVideoBeingLoaded.onNext(true)
        isVideoArchiveValid.onNext(false)
        
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
                
                // Необходимо для того, чтобы в HLS потоке мог быть выбран поток
                // с разрешением превышающим разрешение экрана телефона
                playerItem.preferredMaximumResolution = CGSize(width: 3840, height: 2160)
                
                self?.playerArchive?.replaceCurrentItem(with: playerItem)
                
                self?.isVideoArchiveValid.onNext(true)

                self?.videoArchiveView.isHidden = false
                self?.videoView.isHidden = false
                self?.archiveImageView.isHidden = true
                self?.playerArchive?.play()
            }
        }

    }
    
    private func loadVideoOnline(_ url: URL, isStartLoad: Bool = false) {
        player?.replaceCurrentItem(with: nil)
        
        if let isMuted = try? isVideoMuted.value() {
            playerLayer?.player?.isMuted = isMuted
        } else {
            muteButton.setImage(UIImage(named: "volumeOff"), for: .normal)
            muteButton.setImage(UIImage(named: "volumeOff")?.darkened(), for: [.normal, .highlighted])
            playerLayer?.player?.isMuted = true
        }
        
        loadingAsset?.cancelLoading()
        loadingAsset = nil
        
        let asset = AVAsset(url: url)
        
        loadingAsset = asset
        
        isVideoBeingLoaded.onNext(true)
        isVideoValid.onNext(false)

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
                
                // Необходимо для того, чтобы в HLS потоке мог быть выбран поток
                // с разрешением превышающим разрешение экрана телефона
                playerItem.preferredMaximumResolution = CGSize(width: 3840, height: 2160)
                
                self?.player?.replaceCurrentItem(with: playerItem)
                
                self?.isVideoValid.onNext(true)
                self?.loadedOnlineVideoDate = Date()
                if isStartLoad {
                    self?.dateArchiveUpper.onNext(Date())
                }
                if self?.isVisible == true {
                    self?.player?.play()
                }
            }
        }
    }
    
    private func loadCamera() {
        guard let camera = selectedCamera else {
            return
        }
        doors = camera.doors.enumerated().map { [weak self] index, door in
            guard let button = self?.doorsbutton[index] as? UIButton else {
                return door
            }
            button.imageForNormal = UIImage(named: door.type)
            button.isHidden = false
            return door
        }
        
        let resultingString = camera.video + "/index.m3u8" + "?token=\(camera.token)"
        
        guard let url = URL(string: resultingString) else {
            return
        }
        loadVideoOnline(url, isStartLoad: true)
    }
    
    private func generateThumb(_ day: Date) {
        let lock = NSLock()
        if thumbLoadingQueue.count == 1 {
            guard let thumb = (thumbLoadingQueue.first { $0.day == day }) else {
                lock.lock()
                if let thumbnew = thumbLoadingQueue.last {
                    self.thumbLoadingQueue = [thumbnew]
                    generateThumb(thumbnew.day)
                }
                lock.unlock()
                return
            }
            dateThumbGenerated.onNext(day)
            
            ScreenshotHelper.generateThumbnailFromVideoUrlAsync(
                url: thumb.url,
                forTime: .zero
            ) { cgImage in
                guard let cgImage = cgImage else {
                    return
                }
                DispatchQueue.main.async {
                    self.archiveImageViewImage.image = UIImage(cgImage: cgImage)
                    self.thumbLoadingQueue.removeAll { $0.day == day }
                    lock.lock()
                    if !self.thumbLoadingQueue.isEmpty, let thumbnext = self.thumbLoadingQueue.last {
                        self.thumbLoadingQueue = [thumbnext]
                        self.generateThumb(thumbnext.day)
                    }
                    lock.unlock()
                }
            }
        } else if thumbLoadingQueue.count > 50 {
            lock.lock()
            if !self.thumbLoadingQueue.isEmpty, let thumbnext = self.thumbLoadingQueue.last {
                self.thumbLoadingQueue = [thumbnext]
                self.generateThumb(thumbnext.day)
            }
            lock.unlock()
        }
    }
    
    private func updateEvents(_ daysEvents: EventsDays) {
        events = daysEvents.flatMap { $0.value }.sorted { $0.date < $1.date }
        eventsdiff = zip(events.dropFirst(), events).map { $0.date.timeIntervalSince($1.date) }
        archiveCollectionView.reloadData()
    }
    
    func scrollToDate(_ date: Date?) {
        archiveCollectionView.reloadData()
//        print("------------ GOTO TO DATE", date)
        guard let date = date else {
            archiveCollectionView.setContentOffset(CGPoint(x: 0, y: -49), animated: false)
            return
        }
        let maxRangeDate = ranges.compactMap { $0?.endDate }.max() ?? upperDateLimit
        let startDate = Date(timeIntervalSinceReferenceDate: (maxRangeDate.timeIntervalSinceReferenceDate / Double(deltaTimeInterval)).rounded(.toNearestOrEven) * Double(deltaTimeInterval))
//        var yPos: CGFloat = 0
        let calendar = Calendar.novokuznetskCalendar
        let countDays = (calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: startDate)).day ?? 0) + 1
        
        guard countDays < archiveCollectionView.numberOfSections else {
            return
        }
        
        let items = archiveCollectionView.numberOfItems(inSection: countDays)
        let interval = date.timeIntervalSince(calendar.startOfDay(for: date)).int
        let row = items - interval / deltaTimeInterval - 1
//        print("SECTION", countDays, date, startDate, interval, row)
        if row >= 0, row < items {
            let index = IndexPath(row: row, section: countDays)
            archiveCollectionView.scrollToItem(at: index, at: .top, animated: false)
            dateArchiveUpper.onNext(date)
        }
    }
    
    private func showControls () {
        timelineView.isHidden = false
        exitFullscreenButton.isHidden = false
        onlineButtonsStack.isHidden = false
        UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                self.timelineView.alpha = 1
                self.onlineButtonsStack.alpha = 1
                self.exitFullscreenButton.alpha = 1
            },
            completion: { _ in
            }
        )
    }
    
    private func hideControls () {
        UIView.animate(
            withDuration: 0.5,
            delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                self.timelineView.alpha = 0
                self.onlineButtonsStack.alpha = 0
                self.exitFullscreenButton.alpha = 0
            },
            completion: { _ in
                self.timelineView.isHidden = true
                self.onlineButtonsStack.isHidden = true
                self.exitFullscreenButton.isHidden = true
            }
        )
    }
}

extension FullscreenArchiveIntercomLandscapeViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let maxRangeDate = ranges.compactMap { $0?.endDate }.max() ?? upperDateLimit
        let calendar = Calendar.novokuznetskCalendar
        guard let daysCount = calendar.dateComponents([.day], from: calendar.startOfDay(for:  lowerDateLimit), to: calendar.startOfDay(for: maxRangeDate)).day,
            upperDateLimit > lowerDateLimit else {
            return 1
        }
        return daysCount + 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let maxRangeDate = ranges.compactMap { $0?.endDate }.max() ?? upperDateLimit
        let calendar = Calendar.novokuznetskCalendar
        let endTime = Date(timeIntervalSinceReferenceDate: (upperDateLimit.timeIntervalSinceReferenceDate / Double(deltaTimeInterval)).rounded(.toNearestOrEven) * Double(deltaTimeInterval))

        switch section {
        case .zero:
            return floor(49 / archiveItemHeight).int
        case 1:
            guard let seconds = calendar.dateComponents([.second], from: calendar.startOfDay(for: endTime), to: endTime).second else {
                return 0
            }
            return seconds / deltaTimeInterval
        case calendar.dateComponents([.day], from: calendar.startOfDay(for: lowerDateLimit), to: calendar.startOfDay(for: maxRangeDate)).day! + 1:
            guard let number = calendar.dateComponents([.second], from: calendar.startOfDay(for: lowerDateLimit), to: lowerDateLimit).second else {
                return 0
            }
            return fullSectionCount - number / deltaTimeInterval
        default:
            return fullSectionCount
        }
        return 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withClass: TimelineLandscapeSectionCell.self, for: indexPath)
        
        let calendar = Calendar.novokuznetskCalendar
        var endTime = Date(timeIntervalSinceReferenceDate: (upperDateLimit.timeIntervalSinceReferenceDate / Double(deltaTimeInterval)).rounded(.toNearestOrEven) * Double(deltaTimeInterval))
        var addValue = -indexPath.row * deltaTimeInterval - deltaTimeInterval
        
        switch indexPath.section {
        case .zero:
            addValue = (floor(49 / archiveItemHeight).int - indexPath.row) * deltaTimeInterval - deltaTimeInterval
        case 1:
            break
        default:
            if let sectionDay = calendar.date(byAdding: .day, value: 2 - indexPath.section, to: endTime) {
                endTime = calendar.startOfDay(for: sectionDay)
            }
        }
        
        let timecell = calendar.date(byAdding: .second, value: addValue, to: endTime)!
        let timecellend = calendar.date(byAdding: .second, value: deltaTimeInterval, to: timecell)!
        
        let height = (collectionView.frame.height - 60) / 6.0
//        if view.frame.width < view.frame.height {
//            height = (view.frame.width - 60) / 6.0
//        }
        let width = height / 9 * 16
        var url: URL?
        let isEvent = events.last { ($0.date < timecellend) && ($0.date >= timecell) }
        var isThumb = true
        var countEvents = 0

        if let event = isEvent, let camera = selectedCamera {
            let timestamp = String(timecell.unixTimestamp.int)
            
            let previewString = camera.video +
                "/" +
                timestamp +
                "-preview.mp4" +
                "?token=\(camera.token)"

            url = URL(string: previewString)
            
            let distance = (height + 10) / archiveItemHeight * CGFloat(deltaTimeInterval)
            if let indexEvent = events.firstIndex(of: event),
               indexEvent >= 0, indexEvent < eventsdiff.count,
               eventsdiff[indexEvent] < distance {
                var fullDiff: Double = 0
                for indexDiff in stride(from: eventsdiff.count - 1, through: indexEvent, by: -1) {
                   fullDiff += eventsdiff[indexDiff]
                    if fullDiff > distance {
                        fullDiff = 0
                    }
                }
                isThumb = fullDiff == 0
            }
            countEvents = events.filter { ($0.date < timecellend) && ($0.date >= timecell) }.count

        }
        
        var cellstate: TimelineCellOrder = .small
        let minute = calendar.component(.minute, from: timecell)
        let second = calendar.component(.second, from: timecell)

        switch deltaTimeInterval {
        case 60:
            if minute % 15 == 0 {
                cellstate = .big
            } else if minute % 5 == 0 {
                cellstate = .middle
            }
        case 30:
            if (minute % 15 == 0) && (second == 0) {
                cellstate = .big
            } else if second == 0 {
                cellstate = .middle
            }
        case 15:
            if (minute % 5 == 0) && (second == 0) {
                cellstate = .big
            } else if second == 0 {
                cellstate = .middle
            }
        default: // case 6
            if (minute % 2 == 0) && (second == 0) {
                cellstate = .big
            } else if second % 30 == 0 {
                cellstate = .middle
            }
        }

        let isInArchive =  ranges.contains(where: { ($0!.startDate <= timecell) && ($0!.endDate >= timecell) })
        
        let input = TimelineLandscapeSectionCell.Input(
            time: timecell,
            state: cellstate,
            event: isEvent,
            showThumb: isThumb,
            countEvents: countEvents,
            height: archiveItemHeight,
            widthin: width,
            url: url,
            isInArchive: isInArchive,
            todate: try? dateArchiveUpper.value(),
            delta: deltaTimeInterval,
            itemHeight: archiveItemHeight,
            cache: previewCache
        )
        cell.configureCell(input)
        
        return cell
    }

}

extension FullscreenArchiveIntercomLandscapeViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.zoomContentView
    }
}

extension FullscreenArchiveIntercomLandscapeViewController: UICollectionViewDelegate {
    
    private func reCalcTimelinePosition(_ isFirst: Bool = false) -> Date? {
        var offsetY = archiveCollectionView.contentOffset.y + 49
        
        let calendar = Calendar.novokuznetskCalendar
        
        var datearchive: Date?
        var second = 0
        let maxRangeDate = ranges.compactMap { $0?.endDate }.max() ?? upperDateLimit
        let startDate = Date(timeIntervalSinceReferenceDate: (upperDateLimit.timeIntervalSinceReferenceDate / Double(deltaTimeInterval)).rounded(.toNearestOrEven) * Double(deltaTimeInterval))
        var nextoffset: CGFloat = 0
        
        for index in 1..<archiveCollectionView.numberOfSections {
            let countItems = archiveCollectionView.numberOfItems(inSection: index)
            if index == 1 {
                let startDay = calendar.startOfDay(for: startDate)
                for itemIndex in 0..<countItems {
                    if let attributes = archiveCollectionView.layoutAttributesForItem(at: IndexPath(row: itemIndex, section: index)) {
                        offsetY -= attributes.frame.height
                        if attributes.frame.origin.y != nextoffset {
                            offsetY -= attributes.frame.origin.y - nextoffset
                        }
                        nextoffset = attributes.frame.origin.y + archiveItemHeight
                    }
                    second += deltaTimeInterval
                    if offsetY <= 0 {
                        datearchive = calendar.date(byAdding: .second, value: 0 - second, to: startDate)
                        let outheight = Int(offsetY / archiveItemHeight)
                        if outheight < 0,
                           let date = datearchive,
                           let datecorrection = calendar.date(byAdding: .second, value: -outheight * deltaTimeInterval, to: date) {
                            if datecorrection > upperDateLimit {
                                if datecorrection > maxRangeDate {
                                    upperDateLimit = maxRangeDate
                                } else {
                                    upperDateLimit = datecorrection
                                }
                                loweUpperSelectedTrigger.onNext((lowerDateLimit, upperDateLimit))
                                archiveCollectionView.reloadData()
                            }
//                            if isFirst {
//                                return reCalcTimelinePosition()
//                            }
                        }
                        return datearchive
                    }
                }
            } else {
                guard let day = calendar.date(byAdding: .day, value: 1 - index, to: startDate) else {
                    return nil
                }
                let startDay = calendar.startOfDay(for: day)
                for itemIndex in 0..<countItems {
                    if let attributes = archiveCollectionView.layoutAttributesForItem(at: IndexPath(row: itemIndex, section: index)) {
                        offsetY -= attributes.frame.height
                        if attributes.frame.origin.y != nextoffset {
                            offsetY -= attributes.frame.origin.y - nextoffset
                        }
                        nextoffset = attributes.frame.origin.y + archiveItemHeight
                    }
                    second += deltaTimeInterval
                    if offsetY <= 0 {
                        if offsetY < 0 - archiveItemHeight * 3 {
                            archiveCollectionView.reloadData()
                            if isFirst {
                                return reCalcTimelinePosition()
                            }
                        }
                        return calendar.date(byAdding: .second, value: 0 - second, to: startDate)
                    }
                }
            }
        }
        return datearchive
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == archiveCollectionView {
            guard let date = reCalcTimelinePosition(true) else {
//                dateArchiveUpper.onNext(upperDateLimit)
                return
            }
            dateArchiveUpper.onNext(date)
            isArchiveScrolling.onNext(true)
            transformCell(date)
            
            guard let playerRate = playerArchive?.rate,
                  playerRate == 0 else {
                return
            }
            if let timer = timer,
               timer.isValid {
                timer.invalidate()
            }
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: onTimer)
        }
    }
    
    func transformCell(_ date: Date) {
        for cell in archiveCollectionView.visibleCells {
            if let resurs = cell as? TimelineLandscapeSectionCell {
                resurs.reConfigureCell(date, delta: deltaTimeInterval, itemHeight: archiveItemHeight)
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == archiveCollectionView {
            isArchiveScrolling.onNext(false)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == archiveCollectionView,
           !decelerate {
            isArchiveScrolling.onNext(false)
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if scrollView == archiveCollectionView {
            isArchiveScrolling.onNext(false)
        }
    }
}

extension FullscreenArchiveIntercomLandscapeViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        
        let width = collectionView.frame.width
        if indexPath == IndexPath(row: 0, section: 0) {
            let firstheight: CGFloat = 49.05 - floor(49 / archiveItemHeight) * archiveItemHeight + archiveItemHeight
            return CGSize(width: width, height: firstheight)
        }
        return CGSize(width: width, height: CGFloat(archiveItemHeight))
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        
        let topInset: CGFloat = {
            switch section {
            case 0: return -49
            default: return 0
            }
        }()
        
        let bottomInset: CGFloat = {
            switch section {
            case collectionView.numberOfSections - 1:
                return collectionView.height - 40
            default: return 0
            }
        }()
        
        return UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
    
}

// swiftlint:enable function_body_length cyclomatic_complexity type_body_length file_length closure_body_length
