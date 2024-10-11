//
//  FullscreenArchiveIntercomClipViewController.swift
//  SmartYard
//
//  Created by devcentra on 09.11.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//
// swiftlint:disable type_body_length function_body_length file_length cyclomatic_complexity

import UIKit
import AVKit
import RxSwift
import RxCocoa
import JGProgressHUD
import Lottie
import RxDataSources

class FullscreenArchiveIntercomClipViewController: UIViewController, LoaderPresentable {

    private let preferredPlaybackRate: Float = 1
    private var isInitialScroll: Bool = false

    @IBOutlet private weak var fullStackView: UIStackView!

    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var clipImageView: UIView!
    @IBOutlet private weak var clipImageViewImage: UIImageView!
    @IBOutlet private weak var clipVideoView: UIView!
    @IBOutlet private weak var videoLoadingAnimationView: LottieAnimationView!
    @IBOutlet private weak var clipVideoMuteButton: UIButton!
    @IBOutlet private weak var sizeContentLabel: UILabel!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var downloadButton: UIButton!

    @IBOutlet private weak var archiveCollectionView: UICollectionView!
    
    @IBOutlet private weak var topRangeView: UIView!
    @IBOutlet private weak var leftRangeView: UIView!
    @IBOutlet private weak var rightRangeView: UIView!
    @IBOutlet private weak var bottomRangeView: UIView!
    @IBOutlet private weak var topBorderRange: UIView!
    @IBOutlet private weak var toRangeLabel: UILabel!
    @IBOutlet private weak var intervalRangeLabel: UILabel!
    @IBOutlet private weak var bottomBorderRange: UIView!
    @IBOutlet private weak var fromRangeLabel: UILabel!

    @IBOutlet private weak var zoomActionView: UIView!
    @IBOutlet private weak var zoomInButton: UIButton!
    @IBOutlet private weak var zoomOutButton: UIButton!
    @IBOutlet private weak var zoomLabelButton: UIButton!
    
    @IBOutlet private var zoomLabelCenterXConstraint: NSLayoutConstraint!
    @IBOutlet private var zoomLineWidthConstraint: NSLayoutConstraint!
    @IBOutlet private var topRangeHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var bottomRangeHeightConstraint: NSLayoutConstraint!
        
    var deltaTimeInterval: Int = 6
    var fullSectionCount: Int = 24 * 600
    var archiveItemHeight: CGFloat = 9.0
    private let zoomIndex = BehaviorSubject<CGFloat>(value: 18.0)
    private var thumbLoadingQueue: [(day: Date, url: URL)] = []
    private let previewCache = NSCache<NSString, UIImage>()

    private var player: AVPlayer?
    private weak var playerLayer: AVPlayerLayer?
    private var loadingAsset: AVAsset?
    private let isVideoValid = BehaviorSubject<Bool>(value: false)
    private let isVideoBeingLoaded = BehaviorSubject<Bool>(value: false)
    private let isVideoPlaying = BehaviorSubject<Bool>(value: false)

    private let dateToValue = BehaviorSubject<Date?>(value: nil)
    private let dateFromValue = BehaviorSubject<Date?>(value: nil)
    private let intervalDate = BehaviorSubject<Int>(value: 120)
    private let dateThumbGenerated = BehaviorSubject<Date?>(value: nil)
    private let startEndSelectedTrigger = PublishSubject<(Date, Date)>()
    private let getSizeTrigger = BehaviorSubject<Bool>(value: false)

    var loader: JGProgressHUD?

    private var upperDateLimit: Date = Date()
    private var lowerDateLimit: Date = Date()
    private var clipStartDate: Date?
    private var selectedCamera: CameraExtendedObject?
    private var events: [APIPlog] = []
    private var eventsdiff: [Double] = []
    private let viewModel: FullscreenArchiveIntercomPlayerViewModel

    private var disposeBag = DisposeBag()
    
    init(
        viewmodel: FullscreenArchiveIntercomPlayerViewModel
    ) {
        self.viewModel = viewmodel

        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        playerLayer?.frame = clipVideoView.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        clipImageViewImage.frame = clipImageView.bounds
        zoomLineWidthConstraint.constant = zoomActionView.bounds.width / 2
        
        if !isInitialScroll && !archiveCollectionView.visibleCells.isEmpty {
            isInitialScroll = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self = self else {
                    return
                }
                self.zoomLabelCenterXConstraint.constant = self.zoomActionView.bounds.width / 4
                self.makeStartPosition()
            }
        }

        self.view.layoutIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard isBeingDismissed else {
            return
        }
    }
    
    deinit {
        isInitialScroll = false
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction private func tapCloseButton() {
        if let player = playerLayer {
            player.player?.pause()
        }
        NotificationCenter.default.post(
            name: .archiveFullscreenClipDownloadClosed,
            object: nil
        )
    }
    
    @IBAction private func tapZoomInButton() {
        guard let zoom = try? zoomIndex.value(),
              zoom < maximumScale else {
            return
        }
        let newzoom = (archiveItemHeight + 1) / CGFloat(deltaTimeInterval) * 12
        if newzoom > maximumScale {
            zoomIndex.onNext(maximumScale)
        } else {
            zoomIndex.onNext(newzoom)
        }
    }
    
    @IBAction private func tapZoomOutButton() {
        guard let zoom = try? zoomIndex.value(),
              zoom > minimunScale else {
            return
        }
        let newzoom = (archiveItemHeight - 1) / CGFloat(deltaTimeInterval) * 12
        if newzoom < minimunScale {
            zoomIndex.onNext(minimunScale)
        } else {
            zoomIndex.onNext(newzoom)
        }
    }
    
    @IBAction private func tapPlayButton() {
        guard let isVideoPlaying = try? self.isVideoPlaying.value() else {
            return
        }
        
        if isVideoPlaying {
            self.isVideoPlaying.onNext(false)
        } else {
            
            loadingAsset?.cancelLoading()
            loadingAsset = nil
            
            guard let interval = try? intervalDate.value(),
                  let fromDate = try? dateFromValue.value(),
                  let camera = selectedCamera else {
                return
            }
            
            let timestamp = String(fromDate.unixTimestamp.int)
            
            let resultingString = camera.video + "/index-" + timestamp + "-" + String(interval) + ".m3u8" + "?token=\(camera.token)"
            
            print("DEBUG PLAY", resultingString)
            
            guard let url = URL(string: resultingString) else {
                return
            }
            
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
                    self?.isVideoPlaying.onNext(true)
                    
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePlayer()
        configureSwipe()
        bind()
        configureTimelineView()
    }
    
    private func configureSwipe() {
        
        let panYTopRange = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGestureRecognizerTop)
        )
        topBorderRange.addGestureRecognizer(panYTopRange)
        
        let panYBottomRange = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGestureRecognizerBottom)
        )
        bottomBorderRange.addGestureRecognizer(panYBottomRange)
        
        let panXZoomCenter = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGestureRecognizerZoom)
        )
        zoomLabelButton.addGestureRecognizer(panXZoomCenter)
        
        let zoomCollection = UIPinchGestureRecognizer(
            target: self,
            action: #selector(handleZoomGestureRecognizer)
        )
        archiveCollectionView.addGestureRecognizer(zoomCollection)
    }
    
    var pinching: Bool = false
    var pinchStartScale: CGFloat = 18.0
    let maximumScale: CGFloat = 18.0
    let minimunScale: CGFloat = 2.0
    
    @objc private dynamic func handleZoomGestureRecognizer(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            if let zoomstart = try? zoomIndex.value() {
                pinchStartScale = zoomstart
                pinching = true
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
        case .cancelled:
            pinching = false
        default:
            recognizer.state = .cancelled
        }
    }

    var panTopRange: Bool = false
    var panTopRangeChanged: Bool = false
    var startTopRangeHeight: CGFloat = 0
    
    @objc private dynamic func handlePanGestureRecognizerTop(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            panTopRange = true
            panTopRangeChanged = false
            startTopRangeHeight = topRangeHeightConstraint.constant
        case .changed:
            let height = startTopRangeHeight + recognizer.translation(in: self.view).y
            if height < 49 {
                recognizer.state = .cancelled
                break
            }
            if (archiveCollectionView.frame.height - bottomRangeHeightConstraint.constant - height) < 49 {
                recognizer.state = .cancelled
                break
            }
            topRangeHeightConstraint.constant = height
            panTopRangeChanged = true
            let interval = archiveCollectionView.frame.height - height - bottomRangeHeightConstraint.constant
            self.intervalDate.onNext(Int(interval / archiveItemHeight) * deltaTimeInterval)
            self.archiveCollectionView.reloadData()
            self.updateDatesPositions()
        case .ended, .cancelled:
            panTopRange = false
            if panTopRangeChanged {
                getSizeTrigger.onNext(true)
            }
        default:
            recognizer.state = .cancelled
        }
    }
    
    var panBottomRange: Bool = false
    var panBottomRangeChanged: Bool = false
    var startBottomRangeHeight: CGFloat = 0
    
    @objc private dynamic func handlePanGestureRecognizerBottom(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            panBottomRange = true
            panBottomRangeChanged = false
            startBottomRangeHeight = bottomRangeHeightConstraint.constant
        case .changed:
            let height = startBottomRangeHeight - recognizer.translation(in: self.view).y
            if height < 30 {
                recognizer.state = .cancelled
                break
            }
            if (archiveCollectionView.frame.height - topRangeHeightConstraint.constant - height) < 30 {
                recognizer.state = .cancelled
                break
            }
            bottomRangeHeightConstraint.constant = height
            panBottomRangeChanged = true
            let interval = archiveCollectionView.frame.height - height - topRangeHeightConstraint.constant
            self.intervalDate.onNext(Int(interval / archiveItemHeight) * deltaTimeInterval)
            self.archiveCollectionView.reloadData()
            self.updateDatesPositions()
        case .ended, .cancelled:
            panBottomRange = false
            if panBottomRangeChanged {
                getSizeTrigger.onNext(true)
            }
        default:
            recognizer.state = .cancelled
        }
    }
    
    var panZoom: Bool = false
    var panZoomChanged: Bool = false
    var startZoomYCenter: CGFloat = 0
    
    @objc private dynamic func handlePanGestureRecognizerZoom(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            panZoom = true
            panZoomChanged = false
            startZoomYCenter = zoomLabelCenterXConstraint.constant
        case .changed:
            let offset = startZoomYCenter + recognizer.translation(in: self.view).x
            if offset < 0 - (zoomLineWidthConstraint.constant / 2) {
                recognizer.state = .cancelled
                break
            }
            if offset > (zoomLineWidthConstraint.constant / 2) {
                recognizer.state = .cancelled
                break
            }
            zoomLabelCenterXConstraint.constant = offset
            panZoomChanged = true
            let zoom = (offset + zoomLineWidthConstraint.constant / 2) / zoomLineWidthConstraint.constant * (maximumScale - minimunScale) + minimunScale
            zoomIndex.onNext(zoom)
            self.archiveCollectionView.reloadData()
            self.updateDatesPositions()
        case .ended, .cancelled:
            panZoom = false
            if panZoomChanged {
                getSizeTrigger.onNext(true)
            }
        default:
            recognizer.state = .cancelled
        }
    }
    
    @IBAction private func tapMuteButton() {
        guard let player = self.playerLayer?.player else {
            return
        }
        
        player.isMuted = !player.isMuted
        
        if player.isMuted {
            self.clipVideoMuteButton.setImage(UIImage(named: "volumeOff"), for: .normal)
            self.clipVideoMuteButton.setImage(UIImage(named: "volumeOff")?.darkened(), for: [.normal, .highlighted])
        } else {
            self.clipVideoMuteButton.setImage(UIImage(named: "volumeOn"), for: .normal)
            self.clipVideoMuteButton.setImage(UIImage(named: "volumeOn")?.darkened(), for: [.normal, .highlighted])
        }
    }
    
    private func configurePlayer() {
        
        let player = AVPlayer()
        self.player = player
        
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
        }
        
        playerLayer = AVPlayerLayer(player: player)
        clipVideoView.layer.insertSublayer(playerLayer!, at: 0)
        playerLayer?.removeAllAnimations()
        playerLayer?.backgroundColor = UIColor.black.cgColor
        
        playerLayer?.player?.isMuted = true
        clipVideoMuteButton.setImage(UIImage(named: "volumeOff"), for: .normal)
        clipVideoMuteButton.setImage(UIImage(named: "volumeOff")?.darkened(), for: [.normal, .highlighted])

        setPlayerLayer(playerLayer!)
        
        // MARK: Настройка лоадера
        let animation = LottieAnimation.named("LoaderAnimation")
        
        videoLoadingAnimationView.animation = animation
        videoLoadingAnimationView.loopMode = .loop
        videoLoadingAnimationView.backgroundBehavior = .pauseAndRestore

        // Провека остановилось ли текущее видео
        
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
        
        clipImageView.isHidden = false
        clipVideoView.isHidden = true
        
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
        
        NotificationCenter.default
            .addObserver(self, selector: #selector(playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc func playerItemDidReachEnd(notification: NSNotification) {
        isVideoPlaying.onNext(false)
    }
    
    private func configureTimelineView() {
        archiveCollectionView.register(nibWithCellClass: TimelineSectionCell.self)
        archiveCollectionView.delegate = self
        archiveCollectionView.dataSource = self
        archiveCollectionView.isPagingEnabled = false
        archiveCollectionView.contentInset = UIEdgeInsets(top: 49, left: 0, bottom: 30, right: 0)
        topRangeView.isHidden = true
        bottomRangeView.isHidden = true
        leftRangeView.isHidden = true
        rightRangeView.isHidden = true
    }
    
    private func makeStartPosition() {
        archiveCollectionView.reloadData()
        let calendar = Calendar.novokuznetskCalendar
        let topheight = topRangeHeightConstraint.constant

        if let interval = try? intervalDate.value() {
            let height = archiveCollectionView.bounds.height - topheight - CGFloat(interval / deltaTimeInterval) * archiveItemHeight
            if height < 30 {
                let newinterval = Int(floor((archiveCollectionView.bounds.height - topheight - 30) / archiveItemHeight) * CGFloat(deltaTimeInterval))
                let calendar = Calendar.novokuznetskCalendar
                if let startdate = try? dateToValue.value() {
                    dateFromValue.onNext(calendar.date(byAdding: .second, value: newinterval, to: startdate))
                    intervalDate.onNext(newinterval)
                    bottomRangeHeightConstraint.constant = archiveCollectionView.bounds.height - topheight - CGFloat(newinterval / deltaTimeInterval) * archiveItemHeight
                }
            } else {
                bottomRangeHeightConstraint.constant = height
            }
        }
        
        if let startdate = clipStartDate, let camera = selectedCamera {
            let timestamp = String(startdate.unixTimestamp.int)
            let preview = camera.video +
            "/" +
            timestamp +
            "-preview.mp4" +
            "?token=\(camera.token)"

            if let screenshotUrl = URL(string: preview) {
                thumbLoadingQueue.append((day: startdate, url: screenshotUrl))
                generateThumb(startdate)
            }
            if let interval = try? intervalDate.value() {
                if let todate = calendar.date(byAdding: .second, value: interval, to: startdate) {
                    if todate > upperDateLimit {
                        let interval = upperDateLimit.timeIntervalSince(startdate).int
                        let mininterval = Int(49.0 / archiveItemHeight * CGFloat(deltaTimeInterval))
                        if interval < mininterval {
                            intervalDate.onNext(mininterval)
                            let height = archiveCollectionView.bounds.height - topheight - CGFloat(mininterval / deltaTimeInterval) * archiveItemHeight
                            bottomRangeHeightConstraint.constant = height
                        } else {
                            intervalDate.onNext(interval)
                            let height = archiveCollectionView.bounds.height - topheight - CGFloat(interval / deltaTimeInterval) * archiveItemHeight
                            bottomRangeHeightConstraint.constant = height
                        }
                        scrollToToDate(upperDateLimit)
                    } else {
                        scrollToToDate(todate)
                    }
                }
            }
        } else {
            guard let date = try? dateFromValue.value(),
                  let camera = selectedCamera else {
                return
            }
            let timestamp = String(date.unixTimestamp.int)
            let preview = camera.video +
            "/" +
            timestamp +
            "-preview.mp4" +
            "?token=\(camera.token)"

            if let screenshotUrl = URL(string: preview) {
                thumbLoadingQueue.append((day: date, url: screenshotUrl))
                generateThumb(date)
            }
        }
        topRangeView.isHidden = false
        bottomRangeView.isHidden = false
        leftRangeView.isHidden = false
        rightRangeView.isHidden = false

        getSizeTrigger.onNext(true)
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
                }
            )
            .disposed(by: disposeBag)
        
        isVideoValid
            .asDriver(onErrorJustReturn: false)
            .drive(
                onNext: { [weak self] isVideoValid in
                    self?.clipVideoMuteButton.isHidden = !isVideoValid
                }
            )
            .disposed(by: disposeBag)
        
        isVideoPlaying
            .asDriver(onErrorJustReturn: false)
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isVideoPlaying in
                    if isVideoPlaying {
                        self?.player?.play()
                        self?.playButton.setImage(UIImage(named: "systemPause"), for: .normal)
                        self?.clipVideoView.isHidden = false
                        self?.clipImageView.isHidden = true
                    } else {
                        self?.player?.pause()
                        self?.playButton.setImage(UIImage(named: "systemPlayFill"), for: .normal)
                        self?.clipImageView.isHidden = false
                        self?.clipVideoView.isHidden = true
                    }
                }
            )
            .disposed(by: disposeBag)
        
        zoomIndex
            .asDriver(onErrorJustReturn: 18.0)
            .drive(
                onNext: { [weak self] zoom in
                    guard let self = self else {
                        return
                    }
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
                        print("HEIGHT", multiply, zoom, floor(zoom * multiply))
                        self.archiveItemHeight = floor(zoom * multiply)
                        self.deltaTimeInterval = Int(12 * multiply)
                        self.fullSectionCount = Int(300 / multiply * 24)
                        self.zoomLabelCenterXConstraint.constant = ((zoom - self.minimunScale) / (self.maximumScale - self.minimunScale) - 0.5) * self.zoomLineWidthConstraint.constant
                        let height = self.archiveCollectionView.frame.height - self.topRangeHeightConstraint.constant - self.bottomRangeHeightConstraint.constant
                        let interval = Int(height / self.archiveItemHeight) * self.deltaTimeInterval
                        self.intervalDate.onNext(interval)
                        let calendar = Calendar.novokuznetskCalendar
                        if let fromdate = try? self.dateFromValue.value(),
                           let todate = calendar.date(byAdding: .second, value: interval, to: fromdate) {
                            print("DATES", fromdate, todate, interval)
                            self.scrollToToDate(todate)
                        } else {
                            self.archiveCollectionView.reloadData()
                        }
                        self.updateDatesPositions()
                        self.getSizeTrigger.onNext(true)
                    }
                }
            )
            .disposed(by: disposeBag)
        
        dateFromValue
            .asDriver(onErrorJustReturn: nil)
            .drive(
                onNext: { [weak self] datearchive in
                    guard let self = self else {
                        return
                    }
                    
                    self.isVideoPlaying.onNext(false)
                    
                    let formatterOnline = DateFormatter()
                    formatterOnline.dateFormat = "HH:mm:ss"
                    formatterOnline.timeZone = Calendar.novokuznetskCalendar.timeZone
                    formatterOnline.locale = Calendar.novokuznetskCalendar.locale
                    
                    guard let date = datearchive else {
                        return
                    }
                    self.fromRangeLabel.text = "от: " + formatterOnline.string(from: date)
                    
                    if let datethumb = try? self.dateThumbGenerated.value(),
                       let camera = self.selectedCamera,
                       abs(date.timeIntervalSince(datethumb)) >= Double(self.deltaTimeInterval) {
                        let timestamp = String(date.unixTimestamp.int)
                        let preview = camera.video +
                        "/" +
                        timestamp +
                        "-preview.mp4" +
                        "?token=\(camera.token)"
                        
                        if let screenshotUrl = URL(string: preview) {
                            self.thumbLoadingQueue.append((day:date, url:screenshotUrl))
                            self.generateThumb(date)
                        }
                    }
                    
                }
            )
            .disposed(by: disposeBag)
        
        dateToValue
            .asDriver(onErrorJustReturn: nil)
            .drive(
                onNext: { [weak self] datearchive in
                    guard let self = self else {
                        return
                    }
                    
                    self.isVideoPlaying.onNext(false)

                    let formatterOnline = DateFormatter()
                    formatterOnline.dateFormat = "HH:mm:ss"
                    formatterOnline.timeZone = Calendar.novokuznetskCalendar.timeZone
                    formatterOnline.locale = Calendar.novokuznetskCalendar.locale
                    
                    guard let date = datearchive else {
                        return
                    }
                    self.toRangeLabel.text = "до: " + formatterOnline.string(from: date)
                    
                }
            )
            .disposed(by: disposeBag)
        
        intervalDate
            .asDriver(onErrorJustReturn: 120)
            .drive(
                onNext: { [weak self] interval in
                    guard let self = self else {
                        return
                    }
                    
                    let intervalFormatter = DateComponentsFormatter()
                    intervalFormatter.unitsStyle = .positional
                    intervalFormatter.allowedUnits = [.hour, .minute, .second]
                    intervalFormatter.zeroFormattingBehavior = .pad
                    
                    self.intervalRangeLabel.text = intervalFormatter.string(from: DateComponents(second: interval))
                }
            )
            .disposed(by: disposeBag)

        getSizeTrigger
            .asDriver(onErrorJustReturn: false)
            .drive(
                onNext: { [weak self] isGetSize in
                    guard isGetSize else {
                        return
                    }
                    self?.sizeContentLabel.text = "Получаем размер..."
                }
            )
            .disposed(by: disposeBag)
        
        let input = FullscreenArchiveIntercomPlayerViewModel.InputClip(
            downloadTrigger: downloadButton.rx.tap.asDriver(),
            backTrigger: backButton.rx.tap.asDriver(),
            getSizeTrigger: getSizeTrigger.asDriver(onErrorJustReturn: false),
            startEndSelectedTrigger: startEndSelectedTrigger.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transformClip(input)

        output.clipsize
            .map { [weak self] size -> String? in
                guard let size = size else {
                    return nil
                }
                self?.getSizeTrigger.onNext(false)
                return size
            }
            .drive(sizeContentLabel.rx.text)
            .disposed(by: disposeBag)

        output.events
            .drive(
                onNext: { [weak self] events in
                    self?.updateEvents(events)
                }
            )
            .disposed(by: disposeBag)
        
        output.selectedCamera
            .drive(
                onNext: { [weak self] camera in
                    guard let camera = camera else {
                        return
                    }
                    self?.selectedCamera = camera
                    self?.headerLabel.text = camera.name
                }
            )
            .disposed(by: disposeBag)
        
        output.selectedDate
            .drive(
                onNext: { [weak self] date in
                    self?.clipStartDate = date
                }
            )
            .disposed(by: disposeBag)
        
        output.lowerUpperDates
            .drive(
                onNext: { [weak self] args in
                    let (lowerdate, upperdate) = args
                    guard let lower = lowerdate, let upper = upperdate else {
                        return
                    }
                    self?.upperDateLimit = upper
                    self?.lowerDateLimit = lower
                    self?.archiveCollectionView.reloadData()
                }
            )
            .disposed(by: disposeBag)
        
        Driver
            .combineLatest(dateFromValue.asDriver(onErrorJustReturn: nil),  dateToValue.asDriver(onErrorJustReturn: nil))
            .debounce(.microseconds(250))
            .filter { args in
                let (datefrom, dateto) = args
                guard let start = datefrom, let end = dateto, start < end else {
                    return false
                }
                return true
            }
            .distinctUntilChanged { $0 == $1 }
            .drive(
                onNext: { [weak self] args in
                    let (startDate, endDate) = args
                    guard let self = self, self.isInitialScroll, let start = startDate, let end = endDate else {
                        return
                    }
                    
                    self.startEndSelectedTrigger.onNext((start, end))
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
                    self.player?.pause()
                    self.clipVideoView.isHidden = true
                    self.clipImageView.isHidden = false
                }
            )
            .disposed(by: disposeBag)
        
        if let playerLayer = playerLayer {
            clipVideoView.layer.insertSublayer(playerLayer, at: 0)
        }
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
                    self.clipImageViewImage.image = UIImage(cgImage: cgImage)
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
    
    func scrollToToDate(_ date: Date) {
        archiveCollectionView.reloadData()
        let startDate = Date(timeIntervalSinceReferenceDate: (upperDateLimit.timeIntervalSinceReferenceDate / Double(deltaTimeInterval)).rounded(.toNearestOrEven) * Double(deltaTimeInterval))
        var yPos: CGFloat = 0
        let calendar = Calendar.novokuznetskCalendar
        let countDays = (calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: date)).day ?? 0) + 1
        if countDays > 1 {
            for index in 1..<countDays {
                if let attributes = archiveCollectionView.collectionViewLayout.layoutAttributesForItem(at: IndexPath(row: 0, section: index)) {
                    yPos += attributes.frame.height *  CGFloat(archiveCollectionView.numberOfItems(inSection: index))
                }
            }
            if let startDay = calendar.date(byAdding: .day, value: 1, to:  calendar.startOfDay(for: date)) {
                yPos += CGFloat(startDay.timeIntervalSince(date) / Double(deltaTimeInterval) * archiveItemHeight)
            }
        } else {
            yPos += CGFloat(startDate.timeIntervalSince(date) / Double(deltaTimeInterval) * archiveItemHeight) - topRangeHeightConstraint.constant
        }
        archiveCollectionView.setContentOffset(CGPoint(x: 0, y: yPos), animated: false)
    }
    
    func updateDatesPositions() {
        guard let interval = try? intervalDate.value() else {
            return
        }
        
        var offsetY = archiveCollectionView.contentOffset.y + topRangeHeightConstraint.constant
        
        let calendar = Calendar.novokuznetskCalendar
        
        var datearchiveto: Date?
        var datearchivefrom: Date?
        var second = 0
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
                        datearchiveto = calendar.date(byAdding: .second, value: 0 - second + floor((topRangeHeightConstraint.constant - 49) / CGFloat(deltaTimeInterval)).int, to: startDate)
                        datearchivefrom = calendar.date(byAdding: .second, value: -interval, to: datearchiveto!)
                        dateToValue.onNext(datearchiveto)
                        dateFromValue.onNext(datearchivefrom)
                        return
                    }
                }
            } else {
                guard let day = calendar.date(byAdding: .day, value: 1 - index, to: startDate) else {
                    return
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
                        datearchiveto = calendar.date(byAdding: .second, value: 0 - second + floor((topRangeHeightConstraint.constant - 49) / CGFloat(deltaTimeInterval)).int, to: startDate)
                        datearchivefrom = calendar.date(byAdding: .second, value: -interval, to: datearchiveto!)
                        dateToValue.onNext(datearchiveto)
                        dateFromValue.onNext(datearchivefrom)
                        return
                    }
                }
            }
        }
        if datearchiveto == nil {
            let startDay = calendar.startOfDay(for: lowerDateLimit)
            second -= lowerDateLimit.timeIntervalSince(startDay).int
            datearchiveto = calendar.date(byAdding: .second, value: 0 - second + floor((topRangeHeightConstraint.constant - 49) / CGFloat(deltaTimeInterval)).int, to: startDate)
            datearchivefrom = calendar.date(byAdding: .second, value: -interval, to: datearchiveto!)
            dateToValue.onNext(datearchiveto)
            dateFromValue.onNext(datearchivefrom)
        }
    }
    
    private func updateEvents(_ daysEvents: EventsDays) {
        events = daysEvents.flatMap { $0.value }.sorted { $0.date < $1.date }
        eventsdiff = zip(events.dropFirst(), events).map { $0.date.timeIntervalSince($1.date) }
        archiveCollectionView.reloadData()
    }
}

extension FullscreenArchiveIntercomClipViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let calendar = Calendar.novokuznetskCalendar
        guard let daysCount = calendar.dateComponents([.day], from: calendar.startOfDay(for:  lowerDateLimit), to: calendar.startOfDay(for: upperDateLimit)).day,
            upperDateLimit > lowerDateLimit else {
            return 1
        }
        return daysCount + 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
        case calendar.dateComponents([.day], from: calendar.startOfDay(for: lowerDateLimit), to: calendar.startOfDay(for: upperDateLimit)).day! + 1:
            guard let number = calendar.dateComponents([.second], from: calendar.startOfDay(for: lowerDateLimit), to: lowerDateLimit).second else {
                return 0
            }
            return fullSectionCount - number / deltaTimeInterval
        default:
            return fullSectionCount
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
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

        let input = TimelineSectionCell.Input(
            time: timecell,
            state: cellstate,
            event: isEvent,
            showThumb: isThumb,
            countEvents: countEvents,
            height: archiveItemHeight,
            widthin: width,
            url: url,
            isInArchive: true,
            todate: nil,
            delta: deltaTimeInterval,
            itemHeight: archiveItemHeight,
            cache: previewCache
        )
        cell.configureCell(input)

        return cell
    }
}

extension FullscreenArchiveIntercomClipViewController: UICollectionViewDelegate {
    
// Тут рассчитывает позицию таймлайна относительно View для отображения времени
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDatesPositions()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        getSizeTrigger.onNext(true)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            getSizeTrigger.onNext(true)
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        getSizeTrigger.onNext(true)
    }
}

extension FullscreenArchiveIntercomClipViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        
        let width = collectionView.frame.width
        if indexPath.section == .zero,
           indexPath.row == .zero {
            let firstheight = 49 - floor(49 / archiveItemHeight) * archiveItemHeight + archiveItemHeight
            return CGSize(width: width, height: CGFloat(firstheight))
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
        
        return UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    }
}
// swiftlint:enable type_body_length function_body_length file_length cyclomatic_complexity
