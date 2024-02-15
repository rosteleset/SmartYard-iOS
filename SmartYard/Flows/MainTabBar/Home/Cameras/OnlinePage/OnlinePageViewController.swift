//
//  OnlinePageViewController.swift
//  SmartYard
//
//  Created by admin on 15.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AVKit
import TouchAreaInsets
import Lottie

protocol OnlinePageViewControllerDelegate: AnyObject {
    
    func onlinePageViewController(_ vc: OnlinePageViewController, didSelectCamera camera: CameraObject)
    
}

class OnlinePageViewController: BaseViewController {
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var cameraContainer: UIView!
    @IBOutlet private weak var fullscreenButton: UIButton!
    @IBOutlet private weak var soundToggleButton: UIButton!
    @IBOutlet private weak var videoLoadingAnimationView: LottieAnimationView!
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    @IBOutlet private var collectionViewHeightConstraint: NSLayoutConstraint!
    
    private var cameras = [CameraObject]()
    private var selectedCameraNumber: Int?
    
    private var loadingAsset: AVAsset?
    
    private let isVideoValid = BehaviorSubject<Bool>(value: false)
    private let isVideoBeingLoaded = BehaviorSubject<Bool>(value: false)
    private let isSoundOn = BehaviorSubject<Bool>(value: false)
    
    weak var delegate: OnlinePageViewControllerDelegate?
    
    private var isInFullscreen = false
    private var hasSound = false
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        title = NSLocalizedString("Online", comment: "")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        player?.replaceCurrentItem(with: nil)
    }
    
    override func viewDidLayoutSubviews() {
        if !isInFullscreen {
            playerLayer?.frame = cameraContainer.bounds
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePlayer()
        configureFullscreenButton()
        configureSoundToggleButton()
        configureCollectionView()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }
    
    func setCameras(_ cameras: [CameraObject], selectedCamera: CameraObject?) {
        self.cameras = cameras
        
        collectionView.reloadData { [weak self] in
            guard let selectedCamera = selectedCamera,
                let index = cameras.firstIndex(of: selectedCamera) else {
                return
            }

            let indexPath = IndexPath(row: index, section: 0)

            self?.collectionView.selectItem(
                at: indexPath,
                animated: false,
                scrollPosition: .top
            )

            self?.reloadCameraIfNeeded(selectedIndexPath: indexPath)
            self?.updateSoundButtonVisibility(for: selectedCamera.hasSound)
        }
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
    
    // swiftlint:disable:next function_body_length
    private func configurePlayer() {
        let player = AVPlayer()
        player.isMuted = true
        self.player = player
        
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
        }
        
        playerLayer = AVPlayerLayer(player: player)
        cameraContainer.layer.insertSublayer(playerLayer!, at: 0)
        playerLayer?.frame = cameraContainer.bounds
        playerLayer?.removeAllAnimations()
        playerLayer?.backgroundColor = UIColor.black.cgColor
        
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
                    
                    self.player?.play()
                    self.isInFullscreen = false
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
    
    private func configureSoundToggleButton() {
        soundToggleButton.setImage(UIImage(named: "SoundOff"), for: .normal)
        soundToggleButton.setImage(UIImage(named: "SoundOn"), for: .selected)
        
        soundToggleButton.touchAreaInsets = UIEdgeInsets(inset: 12)
        
        soundToggleButton.rx.tap
            .withLatestFrom(isSoundOn) { _, isSoundOn in !isSoundOn }
            .bind(to: isSoundOn)
            .disposed(by: disposeBag)
    }
    
    private func updateSoundButtonVisibility(for hasSound: Bool) {
        soundToggleButton.isHidden = !hasSound
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
                        shouldTurnOnSound = try self.isSoundOn.value()
                    } catch {
                        print("Error getting isSoundOn value: \(error)")
                    }
                   
                    let fullscreenVc = FullscreenPlayerViewController(
                        playedVideoType: .online,
                        preferredPlaybackRate: 1,
                        hasSound: self.hasSound,
                        isSoundOn: shouldTurnOnSound
                    )
                    
                    fullscreenVc.modalPresentationStyle = .overFullScreen
                    fullscreenVc.modalTransitionStyle = .crossDissolve
                    fullscreenVc.setPlayerLayer(playerLayer)
                    
                    self.isSoundOn.onNext(false)
                    self.isInFullscreen = true
                    
                    self.present(fullscreenVc, animated: true) {
                        self.player?.play()
                    }
                }
            )
            .disposed(by: disposeBag)
        
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
                    playerLayer.removeAllAnimations()

                    self.player?.play()
                    self.isInFullscreen = false

                    self.isSoundOn.onNext(shouldTurnOnSound)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(nibWithCellClass: CameraNumberCell.self)
        
        collectionView.rx
            .observeWeakly(CGSize.self, "contentSize")
            .subscribe(
                onNext: { [weak self] size in
                    guard let self = self, let uSize = size else {
                        return
                    }
                    
                    self.collectionViewHeightConstraint.constant = uSize.height
                    self.view.setNeedsLayout()
                }
            )
            .disposed(by: disposeBag)
    }
    
    fileprivate func startToPlay(_ url: URL) {
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
    
    private func reloadCameraIfNeeded(selectedIndexPath: IndexPath) {
        let camera = cameras[selectedIndexPath.row]
        
        print("Selected Camera #\(camera.cameraNumber)")
        
        guard camera.cameraNumber != selectedCameraNumber else {
            return
        }
        
        selectedCameraNumber = camera.cameraNumber
        
        delegate?.onlinePageViewController(self, didSelectCamera: camera)
        
        player?.replaceCurrentItem(with: nil)
        
        loadingAsset?.cancelLoading()
        loadingAsset = nil
        
        // При переключении между камерами звук выключается
        isSoundOn.onNext(false)
        
        isVideoBeingLoaded.onNext(true)
        
        camera.updateURLAndExec { [weak self] urlString in
            guard let self = self, let url = URL(string: urlString) else {
                self?.isVideoBeingLoaded.onNext(false)
                return
            }
            self.updateSoundButtonVisibility(for: camera.hasSound)
            self.hasSound = camera.hasSound
            self.startToPlay(url)
        }
        
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
        let cell = collectionView.dequeueReusableCell(withClass: CameraNumberCell.self, for: indexPath)

        cell.configure(curCamera: cameras[indexPath.row])

        return cell
    }

}

extension OnlinePageViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 36, height: 36)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 28
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 24
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: 0, bottom: 24, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        reloadCameraIfNeeded(selectedIndexPath: indexPath)
    }
    
}
