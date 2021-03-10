//
//  CityMapViewController.swift
//  SmartYard
//
//  Created by Александр Васильев on 14.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.

import UIKit
import JGProgressHUD
import RxSwift
import RxCocoa
import RxDataSources
import AVKit
import Lottie

class CityCameraViewController: BaseViewController {
    enum ButtonState {
        case initial, incidents, requestRec
    }
    enum ViewState {
        case normal, compact
    }
    //
    @IBOutlet private var cameraNameConstraints: [NSLayoutConstraint]!
    //
    @IBOutlet private var cameraNameConstraintsMini: [NSLayoutConstraint]!
    
    @IBOutlet private weak var cameraName: UILabel!
    @IBOutlet private weak var cameraAddress: UILabel!
    @IBOutlet private weak var cameraContainer: UIView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var fullscreenButton: UIButton!
    @IBOutlet private weak var videoLoadingAnimationView: AnimationView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var skeletonContainer: UIView!
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var gradientView: UIView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    
    private var camera: CityCameraObject?
    private var videos: [YouTubeVideo]?
    private var playerViewController: AVPlayerViewController?
    private var player: AVPlayer?
    
    private var viewState: ViewState = .normal
    private var buttonState: ButtonState = .initial
    private var loadingAsset: AVAsset?
    
    private let isVideoValid = BehaviorSubject<Bool>(value: false)
    private let isVideoBeingLoaded = BehaviorSubject<Bool>(value: false)
    private let videoTrigger = PublishSubject<String>()
    private let requestRecordTrigger = PublishSubject<Void>()
    
    private var refreshControl = UIRefreshControl()
    
    private let viewModel: CityCameraViewModel
    
    init(viewModel: CityCameraViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /*
        if skeletonContainer.isSkeletonActive {
            skeletonContainer.showSkeletonAsynchronously()
        }
        */
    }
    fileprivate func configureView() {
        fakeNavBar.setText("Карта")
        
        guard let camera = camera else {
            return
        }
        
        //Устанавливаем название камеры и её адрес
        let cameraStrings = camera.name.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: true)
        
        var cameraNameString = ""
        var cameraAddressString = ""
        
        if cameraStrings.count == 2 {
            cameraNameString = String(cameraStrings[0])
            cameraAddressString = String(cameraStrings[1])
        } else {
            cameraNameString = camera.name
        }
        
        cameraName.text = cameraNameString
        cameraAddress.text = cameraAddressString
        
        //настраиваем градиент между кнопкой и CollectionView
        let gradientBackgroundColors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor]
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientBackgroundColors
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.locations = [0.0, 1.0]

        gradientLayer.frame = gradientView.bounds
        gradientView.layer.addSublayer(gradientLayer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        bind()
    }
    
    fileprivate func toggleView() {
        if viewState == .normal {
            UIView.animate(withDuration: 0.5, animations: {
                    self.cameraNameConstraints.forEach { $0.isActive = false }
                    self.cameraNameConstraintsMini.forEach { $0.isActive = true }
                    self.cameraAddress.isHidden = true
                    self.cameraName.font = self.cameraName.font.withSize(24)
                    self.cameraName.textAlignment = .center
                    self.view.layoutIfNeeded()
                }
            )
            viewState = .compact
        }
    }
    
    // swiftlint:disable:next function_body_length
    func bind() {
        let input = CityCameraViewModel.Input(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            videoTrigger: videoTrigger.asDriverOnErrorJustComplete(),
            requestRecordTrigger: requestRecordTrigger.asDriverOnErrorJustComplete(),
            refreshDataTrigger: refreshControl.rx.controlEvent(.valueChanged).asDriver()
        )
        
        let output = viewModel.transform(input)
        
        isVideoBeingLoaded
            .asDriver(onErrorJustReturn: false)
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.videoLoadingAnimationView.isHidden = !isLoading
                    
                    isLoading ? self?.videoLoadingAnimationView.play() : self?.videoLoadingAnimationView.stop()
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
       
        //по нажатию на кнопку переключаем вид (у кнопки по мере переключений будет 2 разных действия)
        button.rx.tap
            .asDriver()
            .debounce(.milliseconds(250))
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    switch self.buttonState {
                    case .incidents:
                        self.toggleView()
                        
                        self.button.setTitle("Запросить запись", for: .normal)
                        self.button.backgroundColor = UIColor.SmartYard.blue
                        self.button.setTitleColor(UIColor.white, for: .normal)
                        
                        self.buttonState = .requestRec
                        
                        self.collectionView.isHidden = false
                    case .requestRec:
                        self.requestRecordTrigger.onNext(())
                    case .initial:
                        break
                    }
                }
            )
            .disposed(by: disposeBag)
        
        output.reloadingFinished
            .drive(
                onNext: { [weak self] in
                    self?.refreshControl.endRefreshing()
                    self?.collectionView.reloadData()
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
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    guard let self = self,
                          self.buttonState == .initial else {
                        return
                    }
                    
                    if isLoading {
                        self.activityIndicatorView.startAnimating()
                    } else {
                        self.activityIndicatorView.stopAnimating()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        /* надо заменить  скелетон для табличной части
         output.isLoading
            .debounce(.milliseconds(2500))
            .drive(
                onNext: { [weak self] shouldBlockInteraction in
                    self?.collectionView.isHidden = shouldBlockInteraction
                    
                    self?.skeletonContainer.isHidden = !shouldBlockInteraction
                    
                    shouldBlockInteraction ?
                        self?.skeletonContainer.showSkeletonAsynchronously() :
                        self?.skeletonContainer.hideSkeleton()
                    
                }
            )
            .disposed(by: disposeBag)
        */
        output.videos
            .drive(
                onNext: { [weak self] videos in
                    guard let self = self else {
                        return
                    }
                    self.activityIndicatorView.isHidden = true
                    self.activityIndicatorView.stopAnimating()
                    
                    self.videos = videos
                    self.collectionView.reloadData()
                    
                    if self.viewState == .normal {
                        if videos.isEmpty {
                            self.button.setTitle("Запросить запись", for: .normal)
                            self.button.backgroundColor = UIColor.SmartYard.blue
                            self.button.setTitleColor(UIColor.white, for: .normal)
                            self.buttonState = .requestRec
                            
                        } else {
                            self.button.setTitle("Проишествия ("+String(self.videos?.count ?? 0)+")", for: .normal)
                            self.button.backgroundColor = UIColor.white
                            self.button.setTitleColor(UIColor.SmartYard.blue, for: .normal)
                            self.buttonState = .incidents
                        }
                    } 
                }
            ).disposed(by: disposeBag)
        
        //Загружаем камеру и инициализируем воспроизведение
        self.camera = output.camera
        configureView()
        configurePlayer()
        configureFullscreenButton()
        loadVideo()
        
    }
    
    deinit {
        player?.replaceCurrentItem(with: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        playerViewController?.view.frame = cameraContainer.bounds
    }
    
    private func configureCollectionView() {
   
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(nibWithCellClass: YTCollectionViewCell.self)
        collectionView.refreshControl = refreshControl
        collectionView.isHidden = true //по умолчанию не показываем список до нажатия на кнопку Проишествия
    }
    
    fileprivate func fixButton() {
        if self.buttonState == .requestRec {
            self.button.setTitle("Запросить запись", for: .normal)
            self.button.backgroundColor = UIColor.SmartYard.blue
            self.button.setTitleColor(UIColor.white, for: .normal)
            self.buttonState = .requestRec
            
        } else {
            self.button.setTitle("Проишествия ("+String(self.videos?.count ?? 0)+")", for: .normal)
            self.button.backgroundColor = UIColor.white
            self.button.setTitleColor(UIColor.SmartYard.blue, for: .normal)
            self.buttonState = .incidents
        }
        if viewState == .compact {
                self.cameraNameConstraints.forEach { $0.isActive = false }
                self.cameraNameConstraintsMini.forEach { $0.isActive = true }
                self.cameraAddress.isHidden = true
                self.cameraName.font = self.cameraName.font.withSize(24)
                self.cameraName.textAlignment = .center
                self.view.layoutIfNeeded()
        }
    }
    
    private func configurePlayer() {
        let playerViewController = AVPlayerViewController()
        playerViewController.videoGravity = .resizeAspect
        playerViewController.showsPlaybackControls = false
        self.playerViewController = playerViewController
        
        let player = AVPlayer()
        playerViewController.player = player
        self.player = player
        
        addChild(playerViewController)
        cameraContainer.insertSubview(playerViewController.view, at: 0)
        playerViewController.didMove(toParent: self)
        
        // MARK: Настройка лоадера
        
        let animation = Animation.named("LoaderAnimation")
        
        videoLoadingAnimationView.animation = animation
        videoLoadingAnimationView.loopMode = .loop
        videoLoadingAnimationView.backgroundBehavior = .pauseAndRestore
        
        // MARK: Когда полноэкранное видео будет закрыто, нужно добавить child controller заново
        
        NotificationCenter.default.rx
            .notification(.onlineFullscreenModeClosed)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self, let playerVc = self.playerViewController else {
                        return
                    }
                    
                    playerVc.showsPlaybackControls = false
                    playerVc.willMove(toParent: nil)
                    playerVc.view.removeFromSuperview()
                    playerVc.removeFromParent()
                    
                    self.addChild(playerVc)
                    self.cameraContainer.insertSubview(playerVc.view, at: 0)
                    playerVc.didMove(toParent: self)
                    self.playerViewController?.view.frame = self.cameraContainer.bounds
                    
                    playerVc.player?.play()
                    
                    //странный баг на iOS 12.4
                    //если был переход в полноэкранный режим, потом поворот экрана и возврат назад, то у кнопки менялся свет текста на непойми какой.
                    //приходится ручками при возврате из полноэкранного режима обновлять значения полей.
                    self.fixButton()
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
    
    private func configureFullscreenButton() {
        fullscreenButton.setImage(UIImage(named: "FullScreen20"), for: .normal)
        fullscreenButton.setImage(UIImage(named: "FullScreen20")?.darkened(), for: [.normal, .highlighted])
        
        fullscreenButton.touchAreaInsets = UIEdgeInsets(inset: 12)
        
        // MARK: При нажатии на кнопку фуллскрина показываем новый VC с видео на весь экран
        
        fullscreenButton.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let playerVc = self?.playerViewController else {
                        return
                    }
                    
                    playerVc.showsPlaybackControls = true
                    playerVc.willMove(toParent: nil)
                    playerVc.view.removeFromSuperview()
                    playerVc.removeFromParent()

                    let fullscreenVc = FullscreenPlayerViewController(
                        playedVideoType: .online,
                        preferredPlaybackRate: 1
                    )
                    
                    fullscreenVc.modalPresentationStyle = .overFullScreen
                    fullscreenVc.modalTransitionStyle = .crossDissolve
                    fullscreenVc.setPlayerViewController(playerVc)

                    self?.present(fullscreenVc, animated: true) {
                        playerVc.player?.play()
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func loadVideo() {
        
        player?.replaceCurrentItem(with: nil)
        
        loadingAsset?.cancelLoading()
        loadingAsset = nil
        guard let camera = camera else {
            return
        }
        
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
                
                //Необходимо для того, чтобы в HLS потоке мог быть выбран поток с разрешением превышающим разрешение экрана телефона
                playerItem.preferredMaximumResolution = CGSize(width: 3840, height: 2160)
                
                self?.player?.replaceCurrentItem(with: playerItem)
                
                if self?.isVisible == true {
                    self?.player?.play()
                }
            }
        }
    }
    
}

extension CityCameraViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos?.count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: YTCollectionViewCell.self, for: indexPath)
        
        cell.configureCell(
            label: self.videos?[indexPath.item].title ?? "",
            isFirst: indexPath.item == 0
        )
        return cell
    }
}

extension CityCameraViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.view.width - 10, height: 53)
    }
    
    func  collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
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
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let video = self.videos?[indexPath.item] else {
            return
        }
        self.videoTrigger.onNext(video.url)
        
    }
}
