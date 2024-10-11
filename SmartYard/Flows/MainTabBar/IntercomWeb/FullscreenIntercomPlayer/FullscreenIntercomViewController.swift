//
//  FullscreenHomePlayerViewController.swift
//  SmartYard
//
//  Created by admin on 30.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable type_body_length function_body_length cyclomatic_complexity closure_body_length file_length

import UIKit
import AVKit
import RxSwift
import RxCocoa
import JGProgressHUD
import Lottie

class FullscreenIntercomPlayerViewController: UIViewController, LoaderPresentable {
    
    private let preferredPlaybackRate: Float = 1
    private var doors: [DoorObject] = []
    private let position: CGRect?

    private var player: AVPlayer?
    private weak var playerLayer: AVPlayerLayer?

    private let apiWrapper: APIWrapper?
    private let activityTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()
    
    private let viewModel: FullscreenIntercomViewModel

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var muteButton: UIButton!
    @IBOutlet private weak var openButtonsCollection: UIView!
    @IBOutlet private weak var videoLoadingAnimationView: LottieAnimationView!

    @IBOutlet private weak var openButton1View: UIView!
    @IBOutlet private weak var openButton2View: UIView!
    @IBOutlet private weak var openButton3View: UIView!
    @IBOutlet private weak var openButton1: CameraLockButton!
    @IBOutlet private weak var openButton2: CameraLockButton!
    @IBOutlet private weak var openButton3: CameraLockButton!
    @IBOutlet private weak var textButton1: UILabel!
    @IBOutlet private weak var textButton2: UILabel!
    @IBOutlet private weak var textButton3: UILabel!

    private var loadingAsset: AVAsset?
    
    private let isVideoValid = BehaviorSubject<Bool>(value: false)
    private let isVideoBeingLoaded = BehaviorSubject<Bool>(value: false)
    
    private var cameras = [CameraObject]()
    private let cameraId: Int
    private let cameraSelectedTrigger = PublishSubject<Int>()

    private var controls: [UIView] = []
    private var timer: Timer?
    
    var loader: JGProgressHUD?

    private var disposeBag = DisposeBag()
    
    init(
        apiWrapper: APIWrapper,
        viewModel: FullscreenIntercomViewModel,
        camId: Int,
        position: CGRect? = nil
    ) {
        self.apiWrapper = apiWrapper
        self.position = position
        self.viewModel = viewModel
        self.cameraId = camId
        
        super.init(nibName: nil, bundle: nil)
       
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction private func tapOpenButton1() {
        let identity = 0
        self.apiWrapper?
            .openDoor(domophoneId: doors[identity].domophoneId, doorId: doors[identity].doorId, blockReason: nil)
            .trackActivity(self.activityTracker)
            .trackError(self.errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
//                    self?.areObjectsGrantAccessed.onNext(newDict)
                    self?.openButton1.isEnabled = false
                    self?.textButton1.isHidden = true
                    self?.closeDoorAccessAfterTimeout(identity: identity)
                }
            )
            .disposed(by: disposeBag)
    }
    
    @IBAction private func tapOpenButton2() {
        var identity = 1
        if doors.count == 2 {
            identity = 0
        }
        self.apiWrapper?
            .openDoor(domophoneId: doors[identity].domophoneId, doorId: doors[identity].doorId, blockReason: nil)
            .trackActivity(self.activityTracker)
            .trackError(self.errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
//                    self?.areObjectsGrantAccessed.onNext(newDict)
                    self?.openButton2.isEnabled = false
                    self?.textButton2.isHidden = true
                    self?.closeDoorAccessAfterTimeout(identity: identity)
                }
            )
            .disposed(by: disposeBag)
    }
    
    @IBAction private func tapOpenButton3() {
        var identity = 2
        if doors.count == 2 {
            identity = 1
        }

        self.apiWrapper?
            .openDoor(domophoneId: doors[identity].domophoneId, doorId: doors[identity].doorId, blockReason: nil)
            .trackActivity(self.activityTracker)
            .trackError(self.errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
//                    self?.areObjectsGrantAccessed.onNext(newDict)
                    self?.openButton3.isEnabled = false
                    self?.textButton3.isHidden = true
                    self?.closeDoorAccessAfterTimeout(identity: identity)
                }
            )
            .disposed(by: disposeBag)
    }
    
    @IBAction private func tapCloseButton() {
        animatedClose()
    }
    
    @IBAction private func tapPlayPauseButton() {
        guard let player = self.playerLayer?.player else {
            return
        }
        
        let newState = !self.playPauseButton.isSelected
        self.playPauseButton.isSelected = newState
        
        player.rate = newState ? self.preferredPlaybackRate : 0
    }
    
    @IBAction private func tapMuteButton() {
        guard let player = self.playerLayer?.player else {
            return
        }

        player.isMuted = !player.isMuted

        if player.isMuted {
            self.muteButton.setImage(UIImage(named: "volumeOff"), for: .normal)
            self.muteButton.setImage(UIImage(named: "volumeOff")?.darkened(), for: [.normal, .highlighted])
        } else {
            self.muteButton.setImage(UIImage(named: "volumeOn"), for: .normal)
            self.muteButton.setImage(UIImage(named: "volumeOn")?.darkened(), for: [.normal, .highlighted])
        }

    }
    
    func onTimer(_: Timer) {
        self.hideControls()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard isBeingDismissed else {
            return
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if !doors.isEmpty {
            if view.frame.size.height > view.frame.size.width {
                var height: CGFloat = view.frame.size.width / 400
                
                if height > 1 {
                    height = 1
                }
                openButtonsCollection.bounds.size = CGSize(width: view.frame.width, height: height * 100)
                openButtonsCollection.heightAnchor.constraint(equalToConstant: height * 100).isActive = true
            } else {
                var height: CGFloat = view.frame.size.height / 400

                if height > 1 {
                    height = 1
                }
                openButtonsCollection.bounds.size = CGSize(width: view.frame.width, height: height * 100)
                openButtonsCollection.heightAnchor.constraint(equalToConstant: height * 100).isActive = true
            }
            DispatchQueue.main.async {
                self.openButton1.layerCornerRadius = self.openButton1.frame.height / 2
                self.openButton2.layerCornerRadius = self.openButton2.frame.height / 2
                self.openButton3.layerCornerRadius = self.openButton3.frame.height / 2
            }
        }
        
        super.viewDidAppear(animated)
        
        UIViewController.attemptRotationToDeviceOrientation()
        
        if self.timer == nil {
            self.showControls()
            self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: onTimer)
        }
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        playerLayer?.frame = contentView.bounds
        playerLayer?.videoGravity = .resizeAspect
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        DispatchQueue.main.async {
            self.scrollView.zoomScale = 1.0
            self.scrollView.contentSize = size
            if size.width > size.height {
                self.scrollView.maximumZoomScale = 7.0
            } else {
                self.scrollView.maximumZoomScale = 2.8
            }
            self.playerLayer?.frame = self.contentView.bounds
            self.playerLayer?.videoGravity = .resizeAspect
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        configurePlayer()
        configureSwipe()
        bind()
        
    }
    
    @objc private dynamic func handleSwipeGestureRecognizer(_ recognizer: UISwipeGestureRecognizer) {
        animatedClose()
    }

    private func animatedClose() {
        muteButton.isHidden = true
        closeButton.isHidden = true
        playPauseButton.isHidden = true
        openButtonsCollection.isHidden = true
        scrollView.backgroundColor = .clear
        contentView.backgroundColor = .clear
        UIView.animate(
            withDuration: 0.7,
            delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                if let playerLayer = self.playerLayer,
                   let position = self.position {
                    self.contentView.bounds = position
                    self.contentView.frame = position
                    self.contentView.layerCornerRadius = 12
                    playerLayer.frame = position
                    playerLayer.player?.pause()
                    playerLayer.cornerRadius = 12
                    playerLayer.videoGravity = .resizeAspectFill
                }
            },
            completion: { _ in
                self.dismiss(animated: true, completion: nil)
            }
        )
    }
    
    private func configureSwipe() {
        
        let swipeLeft = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeGestureRecognizer)
        )
        swipeLeft.direction = .left
        contentView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeGestureRecognizer)
        )
        swipeRight.direction = .right
        contentView.addGestureRecognizer(swipeRight)
        
        let swipeUp = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeGestureRecognizer)
        )
        swipeUp.direction = .up
        contentView.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeGestureRecognizer)
        )
        swipeDown.direction = .down
        contentView.addGestureRecognizer(swipeDown)
        
    }
    
    private func configureDoors() {
        switch doors.count {
        case 1:
            openButtonsCollection.isHidden = false
            openButton1View.isHidden = false
            openButton2View.isHidden = true
            openButton3View.isHidden = true
            textButton1.text = doors[0].name
            textButton1.isHidden = true
            openButton1.setImage(UIImage(named: doors[0].type), for: .normal)
        case 2:
            openButtonsCollection.isHidden = false
            openButton1View.isHidden = true
            openButton2View.isHidden = false
            openButton3View.isHidden = false
            textButton2.text = doors[0].name
            textButton2.isHidden = true
            openButton1.setImage(UIImage(named: doors[0].type), for: .normal)
            textButton3.text = doors[1].name
            textButton3.isHidden = true
            openButton1.setImage(UIImage(named: doors[1].type), for: .normal)
        case 3:
            openButtonsCollection.isHidden = false
            openButton1View.isHidden = false
            openButton2View.isHidden = false
            openButton3View.isHidden = false
            textButton1.text = doors[0].name
            textButton1.isHidden = true
            openButton1.setImage(UIImage(named: doors[0].type), for: .normal)
            textButton2.text = doors[1].name
            textButton2.isHidden = true
            openButton1.setImage(UIImage(named: doors[1].type), for: .normal)
            textButton3.text = doors[2].name
            textButton3.isHidden = true
            openButton1.setImage(UIImage(named: doors[2].type), for: .normal)
        default:
            openButtonsCollection.isHidden = true
        }
        
    }
    
    private func configurePlayer() {
        openButtonsCollection.isHidden = true
        
        let player = AVPlayer()
        self.player = player
        
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
        }
        
        playerLayer = AVPlayerLayer(player: player)
        
        playerLayer?.player?.isMuted = true
        setPlayerLayer(playerLayer!)

        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        
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
        
        controls = []
        controls.append(playPauseButton)
        
        hideControls()
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
    
    private func bind() {
        activityTracker
            .asDriver()
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
        
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
                    self?.muteButton.isHidden = !isVideoValid
                }
            )
            .disposed(by: disposeBag)
        
        var input = FullscreenIntercomViewModel.Input(
            cameraTrigger: cameraSelectedTrigger.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)

        output.cameras
            .drive(
                onNext: { [weak self] cameras in
                    guard let self = self else {
                        return
                    }

                    self.cameras = cameras
                    
                    guard let index = self.cameras.firstIndex(where: { $0.id == self.cameraId }) else {
                        return
                    }
                    
                    self.loadCamera(selectedIndexPath: index)
                    self.doors = self.cameras[index].doors
                    self.configureDoors()
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

        if let playerLayer = playerLayer {
           contentView.layer.insertSublayer(playerLayer, at: 0)
        }

    }
    
    func setMuteButton(icon: String) {
        self.muteButton.setImage(UIImage(named: icon), for: .normal)
        self.muteButton.setImage(UIImage(named: icon)?.darkened(), for: [.normal, .highlighted])
    }
    
    private func loadCamera(selectedIndexPath: Int) {
        let camera = cameras[selectedIndexPath]
        
        print("Selected Camera #\(camera.id)")
        
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
                
//                let colorAttributes = [
//                    AVVideoAllowWideColorKey: true,
//                    AVVideoColorPropertiesKey: [
//                        AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_2020,
//                        AVVideoTransferFunctionKey: AVVideoColorPrimaries_ITU_R_709_2,
//                        AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_2020]] as [String : Any]
//                let playerItemVideoOutput = AVPlayerItemVideoOutput(outputSettings: colorAttributes)
//
//                playerItem.add(playerItemVideoOutput)
                
                // Необходимо для того, чтобы в HLS потоке мог быть выбран поток с разрешением превышающим разрешение экрана телефона
                playerItem.preferredMaximumResolution = CGSize(width: 3840, height: 2160)
                
                self?.player?.replaceCurrentItem(with: playerItem)
                
                if self?.isVisible == true {
                    self?.player?.play()
                    self?.playPauseButton.isSelected = true
                }
            }
        }
    }

}

extension FullscreenIntercomPlayerViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.contentView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
}

extension FullscreenIntercomPlayerViewController {
    func closeDoorAccessAfterTimeout(identity: Int) {
        Timer.scheduledTimer(
            withTimeInterval: 5,
            repeats: false
        ) { [weak self] _ in
            guard let self = self else {
                return
            }

            switch self.doors.count {
            case 1:
                self.openButton1.isEnabled = true
                self.textButton1.isHidden = false
            case 2:
                switch identity {
                case 0:
                    self.openButton2.isEnabled = true
                    self.textButton2.isHidden = false
                case 1:
                    self.openButton3.isEnabled = true
                    self.textButton3.isHidden = false
                default:
                    break
                }
                
            case 3:
                switch identity {
                case 0:
                    self.openButton1.isEnabled = true
                    self.textButton1.isHidden = false
                case 1:
                    self.openButton2.isEnabled = true
                    self.textButton2.isHidden = false
                case 2:
                    self.openButton3.isEnabled = true
                    self.textButton3.isHidden = false
                default:
                    break
                }
            default:
                break
            }
//            self.doors[identity].blocked
        }
    }

    private func showControls () {
        controls.forEach({ $0.isHidden = false })
    }
    
    private func hideControls () {
        controls.forEach({ $0.isHidden = true })
    }
}
// swiftlint:enable type_body_length function_body_length cyclomatic_complexity closure_body_length file_length
