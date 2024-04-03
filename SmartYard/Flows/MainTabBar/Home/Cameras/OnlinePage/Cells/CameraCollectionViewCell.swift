//
//  CameraCollectionViewCell.swift
//  SmartYard
//
//  Created by Александр Попов on 27.01.2024.
//  Copyright © 2024 LanTa. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa
import Lottie

class CameraCollectionViewCell: UICollectionViewCell {
    private var camera: CameraObject? // APICamMap?
    
    var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
  
    var lastImage: UIImage?
    
    @IBOutlet private weak var cameraContainer: UIView!
    @IBOutlet private weak var fullscreenButton: UIButton!
    @IBOutlet private weak var soundToggleButton: UIButton!
    @IBOutlet private weak var videoLoadingAnimationView: LottieAnimationView!
    @IBOutlet weak var image: AutoRefreshingCachedImageView!
    
    private let isVideoValid = BehaviorSubject<Bool>(value: false)
    private let isVideoBeingLoaded = BehaviorSubject<Bool>(value: true)
    private let isSoundOn = BehaviorSubject<Bool>(value: false)
    
    private var isInFullscreen = false
    private var hasSound = false
    
    private var loadingAsset: AVAsset?
    
    private(set) var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureFullscreenButton()
        configureSoundToggleButton()
        bind()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        player?.pause()
        configureFullscreenButton()
        configureSoundToggleButton()
        bind()
    }
    
    override func didMoveToSuperview() {
        if superview != nil {
            player?.play()
        }
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        player?.pause()
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
    
    // swiftlint:disable:next function_body_length
    private func bind() {
        
        isVideoBeingLoaded
            .asDriver(onErrorJustReturn: false)
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    if !(self?.isInFullscreen ?? false) {
                        self?.videoLoadingAnimationView.isHidden = !isLoading
                        isLoading ? self?.videoLoadingAnimationView.play() : self?.videoLoadingAnimationView.stop()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        isVideoValid
            .asDriver(onErrorJustReturn: false)
            .drive(
                onNext: { [weak self] isVideoValid in
                    self?.fullscreenButton.isHidden = !isVideoValid
                }
            )
            .disposed(by: disposeBag)
        
        isSoundOn
            .asDriver(onErrorJustReturn: false)
            .drive(
                onNext: { [weak self] isSoundOn in
                    self?.soundToggleButton.isSelected = isSoundOn
                    self?.player?.isMuted = !isSoundOn
                }
            )
            .disposed(by: disposeBag)
        
        Driver
            .just(
                NotificationCenter.default.rx
                    .notification(UIApplication.didEnterBackgroundNotification)
                    .asDriverOnErrorJustComplete()
                    .mapToVoid()
            )
            .drive(
                onNext: { [weak self] _ in
                    self?.player?.pause()
                }
            )
            .disposed(by: disposeBag)
        
    }
    
    // swiftlint:disable:next function_body_length
    private func configurePlayer() {
        let player = AVPlayer()
        player.isMuted = true
        self.player = player
        
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
        }
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = cameraContainer.bounds
        playerLayer?.videoGravity = .resize
        playerLayer?.removeAllAnimations()
        playerLayer?.backgroundColor = UIColor.clear.cgColor
        
        cameraContainer.layer.insertSublayer(playerLayer!, at: 0)
        
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
                    
                    var shouldTurnOnSound = true
                    do {
                        shouldTurnOnSound = try !(self.isSoundOn.value() || self.player?.isMuted ?? true)
                    } catch {
                        print("Error getting isSoundOn value: \(error)")
                    }
                    
                    playerLayer.removeFromSuperlayer()
                    self.cameraContainer.layer.insertSublayer(playerLayer, at: 0)
                    
                    playerLayer.frame = self.cameraContainer.bounds
                    playerLayer.videoGravity = .resize
                    playerLayer.removeAllAnimations()
                    
                    self.player?.play()
                    self.isInFullscreen = false
                    
                    self.isSoundOn.onNext(shouldTurnOnSound)
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
                
                guard status == .readyToPlay ,
                      let asset = currentItem?.asset,
                      asset.duration.seconds > 0 || asset.duration.flags.rawValue == 17 else {
                    return false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) { [weak self] in
                    
                    guard let asset = self?.player?.currentItem?.asset else {
                        return
                    }
                    
                    if #available(iOS 15.0, *) {
                        let media = asset.loadMediaSelectionGroup(for: .visual) { selectionGroup, err in
                            print(selectionGroup.debugDescription)
                        }
                    } else {
                        // Fallback on earlier versions
                    }
                    
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
    
    private func configureFullscreenButton() {
        fullscreenButton.setImage(UIImage(named: "FullScreen20"), for: .normal)
        fullscreenButton.setImage(UIImage(named: "FullScreen20")?.darkened(), for: [.normal, .highlighted])
        
        fullscreenButton.touchAreaInsets = UIEdgeInsets(inset: 12)
        
        // MARK: При нажатии на кнопку фуллскрина показываем новый VC с видео на весь экран
        
        fullscreenButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self,
                          let playerLayer = self.playerLayer else {
                        return
                    }

                    playerLayer.removeFromSuperlayer()
                    
                    var shouldTurnOnSound = false
                    do {
                        shouldTurnOnSound = try isSoundOn.value()
                    } catch {
                        print("Error getting isSoundOn value: \(error)")
                    }
                    
                    let fullscreenVc = FullscreenPlayerViewController(
                        playedVideoType: .online,
                        preferredPlaybackRate: 1,
                        hasSound: hasSound,
                        isSoundOn: shouldTurnOnSound
                    )
                    
                    fullscreenVc.modalPresentationStyle = .overFullScreen
                    fullscreenVc.modalTransitionStyle = .crossDissolve
                    fullscreenVc.setPlayerLayer(playerLayer)
                    
                    self.isSoundOn.onNext(false)
                    self.isInFullscreen = true
                    
                    if let parentViewController = self.parentViewController {
                        parentViewController.present(fullscreenVc, animated: true, completion: nil)
                    }
                }
                
            )
            .disposed(by: disposeBag)
    }
    
    func startToPlay(_ url: URL) {
        self.isVideoBeingLoaded.onNext(true)
        
        configurePlayer()
        
        let asset = AVAsset(url: url)
        
        loadingAsset = asset
        
        asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) { [weak self, weak asset] in
            guard let asset = asset else {
                return
            }
            
            var tracksError: NSError?
            var durationError: NSError?
            
            let tracksStatus = asset.statusOfValue(forKey: "tracks", error: &tracksError)
            let durationStatus = asset.statusOfValue(forKey: "duration", error: &durationError)
            
            // ВОТ ЗДЕСЬ ОСТАНОВЛЮСЬ
            
            if tracksStatus == .cancelled ||
                tracksStatus == .failed ||
                durationStatus == .cancelled ||
                durationStatus == .failed {
                self?.isVideoBeingLoaded.onNext(false)
                
                DispatchQueue.main.async {
                    self?.playerLayer?.backgroundColor = UIColor.black.cgColor
                }
                
                return
            }
            
            guard tracksStatus == .loaded, durationStatus == .loaded else {
                return
            }
            
            //            print("Audio tracks count: \(asset.tracks(withMediaType: .audio).count)")
            //            print("Video tracks count: \(asset.tracks(withMediaType: .video).count)")
            
            if #available(iOS 15.0, *) {
                let media = asset.loadMediaSelectionGroup(for: .visual) { selectionGroup, err in
                    print(selectionGroup.debugDescription)
                }
            } else {
                // Fallback on earlier versions
            }
            
            // print("Audio present: \(String(describing: asset.mediaSelectionGroup(forMediaCharacteristic: .audible)))")
            // print("tracks value: \(String(describing: asset.value(forKey: "tracks") as? [AVAssetTrack]))")
            
            DispatchQueue.main.async {
                // MARK: Ассет загружен, больше хранить его не нужно
                
                self?.loadingAsset = nil
                
                // MARK: Видео готово к просмотру, засовываем его в плеер
                
                let playerItem = AVPlayerItem(asset: asset)
                
                // Необходимо для того, чтобы в HLS потоке мог быть выбран поток с разрешением превышающим разрешение экрана телефона
                playerItem.preferredMaximumResolution = CGSize(width: 3840, height: 2160)
                
                self?.player?.replaceCurrentItem(with: playerItem)
                
                var shouldTurnOnSound = false
                do {
                    shouldTurnOnSound = try self!.isSoundOn.value()
                } catch {
                    print("Error getting isSoundOn value: \(error)")
                }
                
             //   self?.playerLayer?.backgroundColor = UIColor.clear.cgColor
                                
                self?.player?.play()
                
                
                self?.isVideoBeingLoaded.onNext(false)
            }
        }
    }
    
    func loadVideo() {
        player?.replaceCurrentItem(with: nil)
        
        loadingAsset?.cancelLoading()
        loadingAsset = nil
        
        guard let camera = camera else {
            isVideoValid.onNext(false)
            return
        }
        
        camera.updateURLAndExec { [weak self] urlString in
            guard let self = self, let url = URL(string: urlString) else {
                return
            }
            
            self.startToPlay(url)
        }
    }
    
    func stopVideo() {
        player?.pause()
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
        }
        player = nil
        
        isSoundOn.onNext(false)
    }
    
    func saveLastImage(_ image: UIImage?) {
        self.lastImage = image
    }
    
    func configure(curCamera: CameraObject, cache: NSCache<NSString, UIImage>) {
        self.camera = curCamera
        self.hasSound = curCamera.hasSound
        
        image.backgroundColor = .black
        
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
        }
        player = nil
        
        if let image = lastImage {
            self.image.image = image
        } else {
            self.image.image = nil
        }
        
        self.image.loadImageUsingUrlString(
            urlString: curCamera.previewURL, 
            cache: cache,
            label: nil
        )
        
        soundToggleButton.isHidden = !curCamera.hasSound
    }
}
