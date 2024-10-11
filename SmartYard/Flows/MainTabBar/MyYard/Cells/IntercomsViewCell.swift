//
//  IntercomsViewCell.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 11.04.2024.
//  Copyright © 2024 Layka. All rights reserved.
//
// swiftlint:disable type_body_length function_body_length cyclomatic_complexity

import UIKit
import AVKit
import RxSwift
import RxCocoa
import Lottie
import DropDown
import Kingfisher
import ImageIO

class IntercomsViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var previewImage: UIImageView!
    @IBOutlet private weak var loadingAnimationView: LottieAnimationView!
    @IBOutlet private weak var doorIconImage: UIImageView!
    @IBOutlet private weak var doorCodeView: UIView!
    @IBOutlet private weak var doorCodeLabel: UILabel!
    @IBOutlet private weak var menuButton: UIButton!
    @IBOutlet private weak var playVideoButton: UIButton!
    @IBOutlet private weak var fullscreenButton: UIButton!
    @IBOutlet private weak var videoView: UIView!
    @IBOutlet private weak var shareButton: UIButton!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var opendoorButton: UIButton!
    @IBOutlet private weak var imageTimeLabel: UILabel!
    
    @IBOutlet private weak var doorCoreViewWidthConstraint: NSLayoutConstraint!
    
    weak var delegate: MyYardIntercomsCellProtocol?
    private var urlString: String?
    var intercom: IntercomCamerasObject?
    var camera: CameraInversObject?
    private let downloader = ImageDownloader.default
    private let cache = ImageCache.default
    private var downloadTask: DownloadTask?
    private var dateTimeOriginal: Date?
    private var timer: Timer?
    private var timerInterval: Timer?
    private var dateCache: NSCache<NSString, NSDate>?
    private let formatterIntervalDay = DateComponentsFormatter()
    private let formatterIntervalHour = DateComponentsFormatter()
    private let formatterIntervalMinute = DateComponentsFormatter()
    private let formatterInterval = DateComponentsFormatter()
    private var intervalText: String?
    private var updateLock: Bool = false

    private let intercomsMenu = DropDown()

    private var player: AVPlayer?
    private weak var playerLayer: AVPlayerLayer?
    private var loadingAsset: AVAsset?
    private let isVideoValid = BehaviorSubject<Bool>(value: false)
    private let preferredPlaybackRate: Float = 1

    private var disposeBag = DisposeBag()

    @IBAction private func showCamerasMenu() {
        intercomsMenu.show()
    }
    @IBAction private func shareOpendoor() {
        delegate?.didTapShare(for: self)
    }
    @IBAction private func showFullscreen() {
        delegate?.didTapFullScreen(for: self)
    }
    @IBAction private func playVideo() {
        if let isVideoValid = try? isVideoValid.value(), isVideoValid,
           let player = player, let item = player.currentItem {
            if item.status == .readyToPlay, player.rate == 0 {
                NotificationCenter.default.post(name: .stopAllCamerasPlaying, object: camera)
                downloadTask?.cancel()
                timer?.invalidate()
                player.play()
                previewImage.isHidden = true
                playVideoButton.imageForNormal = UIImage(named: "systemPause")
                imageTimeLabel.isHidden = true
                timerInterval?.invalidate()
            } else {
                stopPlayer()
            }
        }
    }
    
    @IBAction private func tapOpendoor() {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            options: [.curveLinear],
            animations: {
                self.opendoorButton.imageForNormal = UIImage(named: "UnlockTemp")
                self.opendoorButton.tintColor = UIColor.SmartYard.darkGreen
            }
        )
        
        Timer.scheduledTimer(
            withTimeInterval: 5,
            repeats: false
        ) { [weak self] _ in
            guard let self = self else {
                return
            }
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                options: [.curveLinear],
                animations: {
                    self.opendoorButton.imageForNormal = UIImage(named: "LockTemp")
                    self.opendoorButton.tintColor = UIColor.white
                }
            )
        }

        delegate?.didTapOpenDoor(for: self)
    }

    func stopPlayer() {
        player?.pause()
        previewImage.isHidden = false
        timerInterval?.invalidate()
        playVideoButton.imageForNormal = UIImage(named: "systemPlayFill")
        updateTimer(1)
    }
    
    func stopAllRefresh() {
        downloadTask?.cancel()
        timer?.invalidate()
        timerInterval?.invalidate()
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        loadingAsset?.cancelLoading()
        loadingAsset = nil
        previewImage.isHidden = false
        playVideoButton.imageForNormal = UIImage(named: "systemPlayFill")
        updateLock = true
    }
    
    func restoreAllRefresh() {
        updateLock = false
        loadVideo()
    }

    private func setup() {
        previewImage.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapImage(_:)))
        previewImage.addGestureRecognizer(tapGesture)
        
        formatterInterval.unitsStyle = .short
        formatterInterval.calendar?.locale = .current
        formatterInterval.allowedUnits = [.second]

        formatterIntervalMinute.unitsStyle = .short
        formatterIntervalMinute.calendar?.locale = .current
        formatterIntervalMinute.allowedUnits = [.minute]

        formatterIntervalHour.unitsStyle = .short
        formatterIntervalHour.calendar?.locale = .current
        formatterIntervalHour.allowedUnits = [.hour]

        formatterIntervalDay.unitsStyle = .short
        formatterIntervalDay.calendar?.locale = .current
        formatterIntervalDay.allowedUnits = [.day]
    }

    @objc func handleTapImage(_ sender: UITapGestureRecognizer) {
//        self.delegate?.didTapPreviewImage(for: self)
    }
    
    private func viewLoader() {
        let animation = LottieAnimation.named("LoaderAnimationGrey")
        
        loadingAnimationView.animation = animation
        loadingAnimationView.loopMode = .loop
        loadingAnimationView.backgroundBehavior = .pauseAndRestore
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setup()
        configurePlayer()
        viewLoader()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        playerLayer?.frame = videoView.bounds
        playerLayer?.videoGravity = .resizeAspectFill
    }
    
    func updateCode(code: String) {
        intercom?.doorcode = code
        doorCodeLabel.text = code
    }

    private func configurePlayer() {
        
        let player = AVPlayer()
        self.player = player
        
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
        }
        
        playerLayer = AVPlayerLayer(player: player)
        videoView.layer.insertSublayer(playerLayer!, at: 0)
        playerLayer?.removeAllAnimations()
        playerLayer?.backgroundColor = UIColor.black.cgColor
        playerLayer?.player?.isMuted = true

        setPlayerLayer(playerLayer!)
        
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
    
    private func setPlayerLayer(_ playerLayer: AVPlayerLayer) {
        
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
    
    func updateImage() {
        downloadTask?.cancel()
        timer?.invalidate()
        
        guard let urlString = urlString, let dateCache = dateCache, let url = URL(string: urlString), !updateLock else {
            return
        }

        let retry = DelayRetryStrategy(maxRetryCount: 5, retryInterval: .accumulated(2))
        let processor = ExifProcessor(dateCache: dateCache, urlString: urlString) |> DownsamplingImageProcessor(size: self.previewImage.size)
        let options: [KingfisherOptionsInfoItem] = [.processor(processor), .scaleFactor(UIScreen.main.scale), .forceRefresh, .retryStrategy(retry)]
        
        downloadTask = downloader.downloadImage(with: url, options: options) { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch (result) {
            case .success(let image):
                DispatchQueue.main.async {
                    self.loadingAnimationView.isHidden = true
                    self.loadingAnimationView.stop()
                    
                    if let date = dateCache.object(forKey: urlString as NSString) as? Date {
                        self.dateTimeOriginal = date
                        self.updateInterval()
                    }

                    self.cache.store(image.image, forKey: urlString)
                    self.previewImage.image = image.image
                    self.updateTimer(6)
                }
            case .failure(let error):
//                print(error.errorDescription)
                DispatchQueue.main.async {
                    self.updateTimer(15)
                }
            }
        }
    }
    
    private func updateInterval() {
        timerInterval?.invalidate()
        
        guard let imageDate = dateTimeOriginal, previewImage.isHidden == false else {
            imageTimeLabel.isHidden = true
            return
        }
        let interval = imageDate.distance(to: Date())
        intervalText = {
            if interval < 0 {
                return formatterInterval.string(from: 0)
            }
            switch interval {
            case 0..<60:
                return formatterInterval.string(from: interval)
            case 60..<3600:
                return formatterIntervalMinute.string(from: interval)
            case 3600..<86400:
                return formatterIntervalHour.string(from: interval)
            default:
                return formatterIntervalDay.string(from: interval)
            }
        }()

        DispatchQueue.main.async {
            self.imageTimeLabel.text = self.intervalText
            self.imageTimeLabel.isHidden = false
        }
        
        timerInterval = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.updateInterval()
        }
    }
    
    private func updateTimer(_ interval: TimeInterval) {
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.updateImage()
        }
    }

    func configureCell(
        intercom: IntercomCamerasObject,
        camera: CameraInversObject,
        urlString: String,
        dateCache: NSCache<NSString, NSDate>
    ) {
        playVideoButton.isHidden = true
//        opendoorButton.isHidden = true
        fullscreenButton.isHidden = true
        
        self.intercom = intercom
        self.camera = camera
        self.urlString = urlString
        self.updateLock = false
        self.dateCache = dateCache
        self.dateTimeOriginal = nil

        self.doorIconImage.image = UIImage(named: intercom.type?.iconImageName ?? "HouseIcon")
        
        self.addressLabel.text = camera.name
        self.addressLabel.layer.shadowRadius = 2
        self.addressLabel.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.addressLabel.layer.shadowColor = UIColor.black.cgColor
        self.addressLabel.layer.shadowOpacity = 1.0
        
        self.timerInterval?.invalidate()
        self.imageTimeLabel.isHidden = true
        self.imageTimeLabel.layer.shadowRadius = 0.8
        self.imageTimeLabel.layer.shadowOffset = CGSize(width: 1.5, height: 1.5)
        self.imageTimeLabel.layer.shadowColor = UIColor.black.cgColor
        self.imageTimeLabel.layer.shadowOpacity = 1.0

        intercomsMenu.anchorView = menuButton
        intercomsMenu.direction = .bottom
        intercomsMenu.bottomOffset = CGPoint(x: 0, y: (intercomsMenu.anchorView?.plainView.bounds.height)!)
        intercomsMenu.backgroundColor = UIColor.white
        intercomsMenu.separatorColor = UIColor.darkGray
        intercomsMenu.dismissMode = .onTap
        intercomsMenu.cellHeight = 44
        intercomsMenu.cornerRadius = 8
        
//        switch intercom.type {
//        case .barrier:
//            createMenu(dataSource: ["Список событий","Настроить FaceID","Поделиться доступом"])
//            doorCodeView.isHidden = true
//            doorCoreViewWidthConstraint.constant = 0
//        default:
            doorCodeLabel.text = intercom.doorcode
            doorCodeView.isHidden = false
            doorCoreViewWidthConstraint.constant = 56
            createMenu(dataSource: ["Список событий","Обновить код открытия","Настроить FaceID","Поделиться доступом"])
//        }

        stopPlayer()
        loadVideo()
        
        guard let url = URL(string: urlString) else {
            return
        }
        downloadTask?.cancel()
        timer?.invalidate()
        
        if cache.isCached(forKey: urlString) {
            previewImage.kf.cancelDownloadTask()
            downloadTask = previewImage.kf.setImage(with: url) { [weak self] result in
                guard let self = self else {
                    return
                }

                if let dateCache = self.dateCache, let date = dateCache.object(forKey: urlString as NSString) as? Date {
                    self.dateTimeOriginal = date
                    self.updateInterval()
                }
                self.loadingAnimationView.isHidden = true
                self.loadingAnimationView.stop()
                self.updateTimer(1)
            }
        } else {
            previewImage.image = nil
            self.loadingAnimationView.isHidden = false
            self.loadingAnimationView.play()
            
            let retry = DelayRetryStrategy(maxRetryCount: 5, retryInterval: .accumulated(2))
            let processor = ExifProcessor(dateCache: dateCache, urlString: urlString) |> DownsamplingImageProcessor(size: self.previewImage.size)
            let options: [KingfisherOptionsInfoItem] = [.processor(processor), .scaleFactor(UIScreen.main.scale), .cacheOriginalImage, .retryStrategy(retry)]
            downloadTask = downloader.downloadImage(with: url, options: options) { [weak self] result in
                guard let self = self else {
                    return
                }
                
                switch (result) {
                case .success(let image):
                    DispatchQueue.main.async {
                        self.loadingAnimationView.isHidden = true
                        self.loadingAnimationView.stop()
                        
                        if let date = dateCache.object(forKey: urlString as NSString) as? Date {
                            self.dateTimeOriginal = date
                            self.updateInterval()
                        }
                        self.previewImage.image = image.image
                        self.updateTimer(6)
                    }
                case .failure(let error):
//                    print(error.errorDescription)
                    DispatchQueue.main.async {
                        self.updateTimer(15)
                    }
                }
            }
        }

    }
    
    private func createMenu(dataSource: [String]){
        intercomsMenu.dataSource = dataSource
        intercomsMenu.cellNib = UINib(nibName: "IntercomsMenuCell", bundle: nil)
        if dataSource.count == 4 {
            intercomsMenu.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) -> Void in
                guard let camera = self.camera, let cell = cell as? IntercomsMenuCell else {
                    return
                }
                cell.countLabel.text = ""
                cell.countLabel.isHidden = true
                switch index {
                case .zero: // Список событий
                    cell.iconImage.image = UIImage(named: "EventsList")
                    if let events = self.intercom?.events, events > 0 {
                        cell.countLabel.text = "(" + String(events) + ")"
                        cell.countLabel.isHidden = false
                    }
                case 1: // Обновить код открытия
                    cell.iconImage.image = UIImage(named: "DoorCodeRefresh")
                case 2: // Настроить FaceID
                    cell.iconImage.image = UIImage(named: "SetFaceID")
                case 3: // Поделиться доступом
                    cell.iconImage.image = UIImage(named: "ShareIcon")
                default:
                    break
                }
                cell.separatorInset = .zero
                cell.layoutMargins = .zero
            }
            intercomsMenu.selectionAction = { [weak self] (index: Int, item: String) in
                guard let self = self else {
                    return
                }
                switch index {
                case .zero: // Список событий
                    self.delegate?.didTapEvents(for: self)
                case 1: // Обновить код открытия
                    self.delegate?.didTapCodeRefresh(for: self)
                case 2: // Настроить FaceID
                    self.delegate?.didTapFaceID(for: self)
                case 3: // Поделиться доступом
                    self.delegate?.didTapShare(for: self)
                default:
                    break
                }
                self.intercomsMenu.deselectRow(at: index)
            }
        }else{
            intercomsMenu.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) -> Void in
                guard let camera = self.camera, let cell = cell as? IntercomsMenuCell else {
                    return
                }
                cell.countLabel.text = ""
                cell.countLabel.isHidden = true
                switch index {
                case .zero: // Список событий
                    cell.iconImage.image = UIImage(named: "EventsList")
                    if let events = self.intercom?.events, events > 0 {
                        cell.countLabel.text = "(" + String(events) + ")"
                        cell.countLabel.isHidden = false
                    }
                case 1: // Настроить FaceID
                    cell.iconImage.image = UIImage(named: "SetFaceID")
                case 2: // Поделиться доступом
                    cell.iconImage.image = UIImage(named: "ShareIcon")
                default:
                    break
                }
                cell.separatorInset = .zero
                cell.layoutMargins = .zero
            }
            intercomsMenu.selectionAction = { [weak self] (index: Int, item: String) in
                guard let self = self else {
                    return
                }
                switch index {
                case .zero: // Список событий
                    self.delegate?.didTapEvents(for: self)
                case 1: // Настроить FaceID
                    self.delegate?.didTapFaceID(for: self)
                case 2: // Поделиться доступом
                    self.delegate?.didTapShare(for: self)
                default:
                    break
                }
                self.intercomsMenu.deselectRow(at: index)
            }
        }
    }
    
    private func loadVideo() {
        guard let camera = camera, let url = URL(string: camera.video + "/index.m3u8" + "?token=\(camera.token)") else {
            return
        }

        player?.replaceCurrentItem(with: nil)
        
        loadingAsset?.cancelLoading()
        loadingAsset = nil
        
        let asset = AVAsset(url: url)
        
        loadingAsset = asset
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
                return
            }
            
            guard tracksStatus == .loaded, durationStatus == .loaded else {
                return
            }
            
            DispatchQueue.main.async {
                // MARK: Ассет загружен, больше хранить его не нужно
                self?.loadingAsset = nil
                
                // MARK: Видео готово к просмотру, засовываем его в плеер
                let playerItem = AVPlayerItem(asset: asset)
                
                // Необходимо для того, чтобы в HLS потоке мог быть выбран поток
                // с разрешением превышающим разрешение экрана телефона
                playerItem.preferredMaximumResolution = CGSize(width: 3840, height: 2160)
                
                self?.player?.replaceCurrentItem(with: playerItem)
                
                self?.playVideoButton.isHidden = false
                self?.opendoorButton.isHidden = false
                self?.fullscreenButton.isHidden = false
            }
        }
    }
}
// swiftlint:enable type_body_length function_body_length cyclomatic_complexity
