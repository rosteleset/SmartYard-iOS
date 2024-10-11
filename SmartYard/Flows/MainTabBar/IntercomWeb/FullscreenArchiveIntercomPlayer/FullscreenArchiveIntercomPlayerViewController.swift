//
//  FullscreenArchiveIntercomPlayerViewController.swift
//  SmartYard
//
//  Created by devcentra on 04.10.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length type_body_length file_length cyclomatic_complexity closure_body_length

import UIKit
import AVKit
import RxSwift
import RxCocoa
import JGProgressHUD
import JTAppleCalendar
import Lottie
import RxDataSources

class FullscreenArchiveIntercomPlayerViewController: UIViewController, LoaderPresentable {
    
    private let preferredPlaybackRate: Float = 1
    private var doors: [DoorExtendedObject] = []
    private let layout = TimelineLayout()
    
    @IBOutlet private weak var fullStackView: UIStackView!
    @IBOutlet private weak var spaceView: UIView!
    @IBOutlet private weak var camerasView: UICollectionView!
    
    @IBOutlet private weak var videoView: UIView!
    @IBOutlet private weak var videoOnlineView: UIView!
    @IBOutlet private weak var videoArchiveView: UIView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var imageBackButton: UIButton!
    @IBOutlet private weak var muteButton: UIButton!
    @IBOutlet private weak var liveActionView: UIView!
    @IBOutlet private weak var videoLabelView: UILabel!
    @IBOutlet private weak var openDoor1Button: UIButton!
    @IBOutlet private weak var openDoor2Button: UIButton!
    @IBOutlet private weak var openDoor3Button: UIButton!
    @IBOutlet private weak var shareButton: UIButton!
    @IBOutlet private weak var selectDate: UIButton!
    @IBOutlet private weak var playTimeView: UIView!
    @IBOutlet private weak var goLiveButton: UIButton!
    @IBOutlet private weak var liveViewButton: UIButton!
    
    @IBOutlet private weak var archiveView: UIView!
    @IBOutlet weak var archiveCollectionView: UICollectionView!
    @IBOutlet private weak var videoLoadingAnimationView: LottieAnimationView!
    @IBOutlet private weak var archiveImageView: UIView!
    @IBOutlet private weak var archiveImageViewImage: UIImageView!
    @IBOutlet private weak var archiveImageNotFound: UIImageView!

    @IBOutlet weak var calendarBackView: UIView!
    @IBOutlet weak var calendarContainerView: UIView!
    @IBOutlet weak var calendarView: JTACMonthView!
    @IBOutlet weak var calendarMonthLabel: UILabel!
    @IBOutlet weak var calendarLeftArrowButton: UIButton!
    @IBOutlet weak var calendarRightArrowButton: UIButton!
    @IBOutlet private weak var calendarCloseButton: UIButton!
    @IBOutlet weak var loaderEventView: UIView!

    @IBOutlet private var camerasViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var camerasViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var calendarViewHeightConstraint: NSLayoutConstraint!
    
    private var player: AVPlayer?
    private weak var playerLayer: AVPlayerLayer?
    private var loadingAsset: AVAsset?
    private let isVideoValid = BehaviorSubject<Bool>(value: false)
    private let isVideoBeingLoaded = BehaviorSubject<Bool>(value: false)
    private let isVideoMuted = BehaviorSubject<Bool>(value: true)
    private let isRangesBeingLoaded = BehaviorSubject<Bool>(value: true)
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
    
    private let dateArchiveUpper = BehaviorSubject<Date>(value: Date())
    private let dateThumbGenerated = BehaviorSubject<Date?>(value: nil)
    private let selectedDate = BehaviorSubject<Date>(value: Date())

    private var cameras = [CameraExtendedObject]()
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
    private var portratOrientation: Bool = true

    private func calculateDateLimits(for ranges: [APIArchiveRange]?) {
        upperDateLimit = Date()
        guard let ranges = ranges else {
            lowerDateLimit = Date()
            loweUpperSelectedTrigger.onNext((lowerDateLimit, upperDateLimit))
            return
        }
        lowerDateLimit = ranges.compactMap { $0.startDate }.min()!

        guard let isVideoValid = try? isVideoValid.value() else {
            loweUpperSelectedTrigger.onNext((lowerDateLimit, upperDateLimit))
            return
        }
        if !isVideoValid {
            upperDateLimit = ranges.compactMap { $0.endDate }.max()!
            dateArchiveUpper.onNext(upperDateLimit)
        }
        loweUpperSelectedTrigger.onNext((lowerDateLimit, upperDateLimit))
    }
    
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoView.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        playerArchiveLayer?.frame = videoView.bounds
        playerArchiveLayer?.videoGravity = .resizeAspectFill
        archiveImageViewImage.frame = archiveImageView.bounds
        
        if view.frame.width > view.frame.height {
            let height = view.frame.height / 3 / 16 * 9 + 26
            camerasViewHeightConstraint.constant = height
        } else {
            let height = view.frame.width / 3 / 16 * 9 + 26
            camerasViewHeightConstraint.constant = height
        }
        
        self.view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        portratOrientation = UIDevice.current.orientation == .portrait
        if UIDevice.current.orientation == .unknown {
            portratOrientation = UIApplication.shared.statusBarOrientation == .portrait
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
            if size.height > size.width {
                self.portratOrientation = true
                self.playerLayer?.frame = self.videoView.bounds
                self.playerLayer?.videoGravity = .resizeAspectFill
                self.playerArchiveLayer?.frame = self.videoView.bounds
                self.playerArchiveLayer?.videoGravity = .resizeAspectFill
                self.archiveImageViewImage.frame = self.archiveImageView.bounds
                self.isArchiveScrolling.onNext(false)
            } else {
                self.portratOrientation = false
                self.player?.pause()
                self.playerArchive?.pause()
            }
        }
    }
    
    override open var shouldAutorotate: Bool {
        return true
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @IBAction private func tapCalendarCloseButton() {
        self.calendarBackView.isHidden = true
        self.calendarContainerView.isHidden = true
    }
    
    @IBAction private func tapSelectDateButton() {
        guard let date = try? dateArchiveUpper.value() else {
            setupCalendarHeader(from: upperDateLimit)
            calendarView.selectDates([upperDateLimit])
            calendarView.reloadData(withAnchor: upperDateLimit)
            calendarView.scrollToDate(upperDateLimit)

            calendarBackView.isHidden = false
            calendarContainerView.isHidden = false
            return
        }
        setupCalendarHeader(from: date)
        calendarView.selectDates([date])
        calendarView.reloadData(withAnchor: date)
        calendarView.scrollToDate(date)

        calendarBackView.isHidden = false
        calendarContainerView.isHidden = false
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
    
    @IBAction private func tapShareButton() {
        guard let camera = selectedCamera, upperDateLimit != lowerDateLimit else {
            return
        }
        if let isVideo = try? isVideoValid.value(),
           isVideo, let player = player {
            player.pause()
        }
        if let isVideo = try? isVideoArchiveValid.value(),
           isVideo, let player = player {
            player.pause()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePlayer()
        configurePlayerArchive()
        configureCamerasView()
        configureTimelineView()
        configureCalendarView(disposeBag)
        configureSwipe()
        bind()
    }
    
    private func configureSwipe() {
        
        let swipeUpLA = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeGestureRecognizer)
        )
        swipeUpLA.direction = .up
        liveActionView.addGestureRecognizer(swipeUpLA)
        let swipeUpAI = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeGestureRecognizer)
        )
        swipeUpAI.direction = .up
        archiveImageView.addGestureRecognizer(swipeUpAI)
        let swipeUpVideo = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeGestureRecognizer)
        )
        swipeUpVideo.direction = .up
        videoView.addGestureRecognizer(swipeUpVideo)
        
        let swipeDownLA = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeGestureRecognizer)
        )
        swipeDownLA.direction = .down
        liveActionView.addGestureRecognizer(swipeDownLA)
        let swipeDownAI = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeGestureRecognizer)
        )
        swipeDownAI.direction = .down
        archiveImageView.addGestureRecognizer(swipeDownAI)
        let swipeDownVideo = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeGestureRecognizer)
        )
        swipeDownVideo.direction = .down
        videoView.addGestureRecognizer(swipeDownVideo)
        
        let zoomCollection = UIPinchGestureRecognizer(
            target: self,
            action: #selector(handleZoomGestureRecognizer)
        )
        archiveCollectionView.addGestureRecognizer(zoomCollection)
        
        let tapCalendarBack = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapCalendarBack)
        )
        calendarBackView.addGestureRecognizer(tapCalendarBack)
    }

    @objc private dynamic func handleTapCalendarBack(_ recognizer: UITapGestureRecognizer) {
        self.calendarBackView.isHidden = true
        self.calendarContainerView.isHidden = true
    }
    
    var pinching: Bool = false
    var pinchStartScale: CGFloat = 1.0
    let maximumScale: CGFloat = 18.0
    let minimunScale: CGFloat = 1.0
    
    @objc private dynamic func handleZoomGestureRecognizer(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            if let zoomstart = try? zoomIndex.value() {
                pinchStartScale = zoomstart
                pinching = true
                isArchiveScrolling.onNext(true)
            }
        case .changed:
            if pinching {
                let newzoom = pinchStartScale * recognizer.scale
                if newzoom >= minimunScale {
                    if newzoom > maximumScale {
                        if let currentzoom = try? zoomIndex.value(),
                           currentzoom < maximumScale {
                            zoomIndex.onNext(maximumScale)
                        }
                    } else {
                        zoomIndex.onNext(newzoom)
                    }
                } else {
                    if let currentzoom = try? zoomIndex.value(),
                       currentzoom > minimunScale {
                        zoomIndex.onNext(minimunScale)
                    }
                }
            }
        case .ended:
            pinching = false
            isArchiveScrolling.onNext(false)
        case .cancelled:
            pinching = false
            isArchiveScrolling.onNext(false)
        default:
            recognizer.state = .cancelled
        }
    }

    @objc private dynamic func handleSwipeGestureRecognizer(_ recognizer: UISwipeGestureRecognizer) {
        switch recognizer.direction {
        case .up:
            UIView.animate(
                withDuration: 0.8,
                delay: 0.0,
                options: .curveEaseInOut,
                animations: {
                    self.spaceView.isHidden = true
                    self.camerasView.isHidden = true
                    self.fullStackView.layoutIfNeeded()
                },
                completion: nil
            )
            
        case .down:
            UIView.animate(
                withDuration: 0.8,
                delay: 0.0,
                options: .curveEaseInOut,
                animations: {
                    self.spaceView.isHidden = false
                    self.camerasView.isHidden = false
                    self.fullStackView.layoutIfNeeded()
                },
                completion: nil
            )
            
        default:
            break
        }
    }
    
    private func configurePlayer() {
        
        doorsbutton = [
            openDoor1Button,
            openDoor2Button,
            openDoor3Button
        ]
        doorsbutton.map {
            $0.isHidden = true
            $0.layerBorderWidth = 2
            $0.layerBorderColor = UIColor.SmartYard.blue
            $0.layerCornerRadius = $0.frame.width / 2
            $0.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
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

            if (self.archiveCollectionView.isDragging || self.archiveCollectionView.isDecelerating), !self.pinching {
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
            self.selectDate.setTitle(formatterCalendar.string(from: date), for: .normal)
            self.selectedDate.onNext(date)
            
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
    
    func setCameras(_ cameras: [CameraExtendedObject]) {
        self.cameras = cameras
        
        camerasView.reloadData { [weak self] in
            guard let self = self, let selectedCamera = self.selectedCamera, let index = cameras.firstIndex(of: selectedCamera) else {
                return
            }
            
            let indexPath = IndexPath(row: index, section: 0)
            
            self.camerasView.selectItem(
                at: indexPath,
                animated: false,
                scrollPosition: .centeredHorizontally
            )
            
        }
    }
    
    private func configureTimelineView() {
        archiveCollectionView.delegate = self
        archiveCollectionView.dataSource = self
        archiveCollectionView.register(nibWithCellClass: TimelineSectionCell.self)
        archiveCollectionView.isPagingEnabled = false
        archiveCollectionView.contentInset = UIEdgeInsets(top: 49, left: 0, bottom: 40, right: 0)
        
//        archiveCollectionView.collectionViewLayout = layout
        
        liveViewButton.isHidden = true
        playTimeView.isHidden = true
        goLiveButton.isHidden = true
    }
    
    private func configureCamerasView() {
        camerasView.delegate = self
        camerasView.dataSource = self
        
        camerasView.register(nibWithCellClass: CameraPreviewCell.self)
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
        
        zoomIndex
            .asDriver(onErrorJustReturn: 1.0)
            .drive(
                onNext: { [weak self] zoom in
                    guard let self = self else {
                        return
                    }
                    let timenow = try? self.selectedDate.value()
                    var multiply = 0.0
                    switch zoom {
                    case 0..<2:
                        multiply = 5.0
                    case 2..<4:
                        multiply = 2.5
                    case 4..<8:
                        multiply = 1.25
                    default:
                        multiply = 0.5
                    }
                    if self.archiveItemHeight != floor(zoom * multiply) {
                        if self.playerArchive?.rate != 0 {
                            self.playerArchive?.pause()
                        }
                        print("HEIGHT", multiply, zoom, floor(zoom * multiply))
                        self.archiveItemHeight = floor(zoom * multiply)
                        self.deltaTimeInterval = Int(12 * multiply)
                        self.fullSectionCount = Int(300 / multiply * 24)
                        self.scrollToDate(timenow)
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
                          self.portratOrientation,
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
                    self.selectedDate.onNext(datearchive)
                    let maxRangeDate = self.ranges.compactMap { $0?.endDate }.max() ?? self.upperDateLimit
//                    print("MAXRANGE", maxRangeDate, self.upperDateLimit, datearchive, isArchiveScrolling)
                    
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
                        self.selectDate.setTitle(formatterCalendar.string(from: self.upperDateLimit), for: .normal)
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
                        self.selectDate.setTitle(formatterCalendar.string(from: datearchive), for: .normal)
                        
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
                    self.selectDate.setTitle(formatterCalendar.string(from: activedate), for: .normal)
                    
                    self.archiveImageNotFound.isHidden = true
                    self.archiveImageViewImage.isHidden = false
                    self.videoView.isHidden = true
                    self.videoOnlineView.isHidden = true
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
        
        let input = FullscreenArchiveIntercomPlayerViewModel.Input(
            selectedCameraTrigger: selectCameraTrigger.asDriverOnErrorJustComplete(),
            updateRangesTrigger: updateRangesForCameraTrigger.asDriver(onErrorJustReturn: nil),
            dateArchiveTrigger: selectedDate.asDriverOnErrorJustComplete(),
            lowerUpperSelectedTrigger: loweUpperSelectedTrigger.asDriverOnErrorJustComplete(),
            buttons: doorsbutton,
            backTrigger: backButton.rx.tap.asDriver(),
            imageBackTrigger: imageBackButton.rx.tap.asDriver(),
            shareTrigger: shareButton.rx.tap.asDriver(),
            muteTrigger: muteButton.rx.tap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.toDate
            .distinctUntilChanged()
            .drive(
                onNext: { [weak self] date in
                    self?.scrollToDate(date)
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
        
        output.selectedCamera
            .drive(
                onNext: { [weak self] camera in
                    guard let self = self, let camera = camera else {
                        return
                    }
                    self.selectedCamera = camera
                    self.videoLabelView.text = camera.name
                    self.videoLabelView.isHidden = false
//                    self.loadCameraOnline(camera: camera)
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
                        self.loadCameraOnline(camera: camera)
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.isEventLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isEventLoading in
                    guard let self = self else {
                        return
                    }
                    self.updateLoader(isEnabled: isEventLoading, detailText: nil, loaderContainer: self.loaderEventView)
                }
            )
            .disposed(by: disposeBag)
        
        output.cameras
            .drive(
                onNext: { [weak self] cameras in
                    guard let self = self else {
                        return
                    }
                    self.setCameras(cameras)
                }
            )
            .disposed(by: disposeBag)
        
        output.rangesForCurrentCamera
            .drive(
                onNext: { [weak self] ranges in
                    guard let self = self else {
                        return
                    }
                    self.isRangesBeingLoaded.onNext(false)
                    guard let ranges = ranges, !ranges.isEmpty else {
                        self.selectDate.isHidden = true
                        self.shareButton.isHidden = true
                        self.ranges = []
                        self.calculateDateLimits(for: nil)
                        self.reloadTimeLineIfNeeded(refreshTop: true)
                        return
                    }
                    self.calculateDateLimits(for: ranges)
                    self.ranges = ranges
                    self.reloadTimeLineIfNeeded(refreshTop: true)
                    self.selectDate.isHidden = false
                    self.shareButton.isHidden = false
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
            .drive(
                onNext: { [weak self] date in
                    guard let self = self,
                          !self.portratOrientation else {
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
        
        NotificationCenter.default.rx
            .notification(.archiveFullscreenClipDownloadClosed)
            .asDriverOnErrorJustComplete()
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
}

extension FullscreenArchiveIntercomPlayerViewController {

    private func updateEvents(_ daysEvents: EventsDays) {
        events = daysEvents.flatMap { $0.value }.sorted { $0.date < $1.date }
        eventsdiff = zip(events.dropFirst(), events).map { $0.date.timeIntervalSince($1.date) }
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
    
    private func loadCameraOnline(camera: CameraExtendedObject) {
        
        print("Selected Camera #\(camera.id)")
        
        doors = camera.doors.enumerated().map { [weak self] index, door in
            guard let button = self?.doorsbutton[index] as? UIButton else {
                return door
            }
            button.imageForNormal = UIImage(named: door.type)
            button.isHidden = false
            self?.viewModel.updateDoorButton(
                identify: index,
                door: door
            )
            return door
        }

        let resultingString = camera.video + "/index.m3u8" + "?token=\(camera.token)"
        
        guard let url = URL(string: resultingString) else {
            return
        }
        loadVideoOnline(url, isStartLoad: true)
    }
    
    private func reloadCameraIfNeeded(selectedIndexPath: IndexPath) {
        let camera = cameras[selectedIndexPath.row]
        
        guard camera.cameraNumber != selectedCameraNumber else {
            return
        }
        
        archiveImageViewImage.image = .none
        selectedCameraNumber = camera.cameraNumber
        events = []
        calculateDateLimits(for: nil)
        reloadTimeLineIfNeeded(refreshTop: true)
        ranges = []
        doors = []
        doorsbutton.map { $0.isHidden = true }
        selectedCameraOnline = false
        videoOnlineView.isHidden = true
        isRangesBeingLoaded.onNext(true)
        viewModel.clearDoorAccess()
        archiveCollectionView.reloadData()
        playTimeView.isHidden = true
        goLiveButton.isHidden = true
        liveViewButton.isHidden = true
        videoLabelView.isHidden = true
        player?.replaceCurrentItem(with: nil)
        loadingAsset?.cancelLoading()
        loadingAsset = nil

        selectCameraTrigger.onNext(camera)
    }

    private func reloadTimeLineIfNeeded(refreshTop: Bool = false) {
        
        if refreshTop {
            archiveCollectionView.setContentOffset(CGPoint(x: 0, y: -49), animated: false)
        }
        archiveCollectionView.reloadData()
    }
    
    func scrollToSection(_ daysCount: Int, date: Date) {
        archiveCollectionView.reloadData()
        let countItem = archiveCollectionView.numberOfItems(inSection: daysCount + 1)
        let minDateRange = ranges.compactMap { $0?.startDate }.min() ?? lowerDateLimit

        isScrollToDate = true
        playerArchive?.pause()
        player?.pause()
        
        if (date <= minDateRange) {
            let yPos = archiveCollectionView.collectionViewLayout.collectionViewContentSize.height - archiveCollectionView.height + 70
//            print("---------------- LAST SECTION", yPos, minDateRange)
            archiveCollectionView.setContentOffset(CGPoint(x: 0, y: yPos), animated: false)
            dateArchiveUpper.onNext(minDateRange)
        } else {
//            print("---------------- GOTO SECTION", daysCount, countItem, date)
            let index = IndexPath(item: countItem - 1, section: daysCount + 1)
            archiveCollectionView.scrollToItem(at: index, at: .top, animated: false)
            dateArchiveUpper.onNext(date)
        }
        isArchiveScrolling.onNext(false)
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
}

extension FullscreenArchiveIntercomPlayerViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == camerasView {
            return 1
        }
        let maxRangeDate = ranges.compactMap { $0?.endDate }.max() ?? upperDateLimit
        let calendar = Calendar.novokuznetskCalendar
        guard let daysCount = calendar.dateComponents([.day], from: calendar.startOfDay(for:  lowerDateLimit), to: calendar.startOfDay(for: maxRangeDate)).day,
            upperDateLimit > lowerDateLimit else {
            return 1
        }
        return daysCount + 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == camerasView {
            return cameras.count
        } else if collectionView == archiveCollectionView {
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
        }
        return 0
    }
    
    func loadCameraImageWithURLSession(for indexPath: IndexPath, urlString: String) {
        let urlSession = URLSession.shared
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        let task = urlSession.dataTask(with: url) { [weak self] (data, response, error) in
            if let data = data, error == nil,
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    guard let self = self else {
                        return
                    }
                    if let cell = self.camerasView.cellForItem(at: indexPath) as? CameraPreviewCell,
                       cell.urlString == urlString {
                        cell.imageIsLoaded(image: image)
                        self.previewCache.setObject(image, forKey: NSString(string: urlString))
                    }
                }
            }
        }
        
        task.resume()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        if collectionView == camerasView {
            let cell = collectionView.dequeueReusableCell(withClass: CameraPreviewCell.self, for: indexPath)

            let previewString = Constants.defaultBackendURL +
                "/event/get/url/" + String(cameras[indexPath.row].id)
            
            loadCameraImageWithURLSession(for: indexPath, urlString: previewString)

            cell.configureCell(camera: cameras[indexPath.row], urlString: previewString, cache: previewCache)
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withClass: TimelineSectionCell.self, for: indexPath)
        
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

        let width = (collectionView.frame.width - 98) / 2.5
//        if [.landscapeRight, .landscapeLeft].contains(UIDevice.current.orientation) {
//            width = (collectionView.frame.height - 98) / 2.5
//        }
        let height = width / 16 * 9
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
        
        let input = TimelineSectionCell.Input(
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

extension FullscreenArchiveIntercomPlayerViewController: UICollectionViewDelegate {
    
    // Тут рассчитывает позицию таймлайна относительно View для отображения времени, переключения
    // на архив и изменения текущей даты календаря
    
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
//            print("+++ DATENOW", date)
            dateArchiveUpper.onNext(date)
            isArchiveScrolling.onNext(true)
            transformCell(date)
        }
    }
    
    func transformCell(_ date: Date){
        for cell in archiveCollectionView.visibleCells {
            if let resurs = cell as? TimelineSectionCell {
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

extension FullscreenArchiveIntercomPlayerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        
        if collectionView == camerasView {
            let width = collectionView.frame.width / 3
            let height = width / 16 * 9 + 26
            
            return CGSize(width: width, height: height)
        }
      
        let width = collectionView.frame.width
        if indexPath == IndexPath(row: 0, section: 0) {
            let firstheight: CGFloat = 49.05 - floor(49 / archiveItemHeight) * archiveItemHeight + archiveItemHeight
            return CGSize(width: width, height: firstheight)
        }
        return CGSize(width: width, height: archiveItemHeight)
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
        if collectionView == camerasView {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        
        let topInset: CGFloat = {
            switch section {
            case 0: return -49
            default: return 0
            }
        }()
        
        let bottomInset: CGFloat = {
            switch section {
            case collectionView.numberOfSections - 1:
                return collectionView.height - 124
            default: return 0
            }
        }()
        
        return UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == camerasView {
            reloadCameraIfNeeded(selectedIndexPath: indexPath)
            return
        }
    }
    
}
// swiftlint:enable function_body_length type_body_length file_length cyclomatic_complexity closure_body_length
