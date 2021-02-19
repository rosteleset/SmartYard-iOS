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


class CityCameraViewController: BaseViewController, LoaderPresentable {
    
    
    @IBOutlet private weak var cameraName: UILabel!
    @IBOutlet var cameraNameConstraints: [NSLayoutConstraint]!
    @IBOutlet var cameraNameConstraintsMini: [NSLayoutConstraint]!
    
    @IBOutlet private weak var cameraAddress: UILabel!
    @IBOutlet private weak var cameraContainer: UIView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var fullscreenButton: UIButton!
    @IBOutlet private weak var videoLoadingAnimationView: AnimationView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var skeletonContainer: UIView!
    @IBOutlet private weak var button: UIButton!
    
    private var camera: CityCameraObject?
    private var videos: [YouTubeVideo]?
    private var playerViewController: AVPlayerViewController?
    private var player: AVPlayer?
    
    private var isMiniView = false
    private var loadingAsset: AVAsset?
    
    private let isVideoValid = BehaviorSubject<Bool>(value: false)
    private let isVideoBeingLoaded = BehaviorSubject<Bool>(value: false)
    private let videoTrigger = PublishSubject<String>()
    
    var loader: JGProgressHUD?
    
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
        
        guard let camera = camera else { return }
        
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
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        bind()
    }
    
    fileprivate func toggleView() {
        if isMiniView {
            //
            
        } else {
            UIView.animate(withDuration: 0.5, animations: {
                    self.cameraNameConstraints.map { $0.isActive = false }
                    self.cameraNameConstraintsMini.map { $0.isActive = true }
                    self.cameraAddress.isHidden = true
                    self.cameraName.font = self.cameraName.font.withSize(24)
                    self.cameraName.textAlignment = .center
                    
                    self.button.setTitle("Запросить запись", for: .normal)
                    self.button.backgroundColor = UIColor.SmartYard.blue
                    self.button.titleColorForNormal = UIColor.white
                    
                    self.view.layoutIfNeeded()
                }
            )
            isMiniView = true
        }
    }
    
    func bind() {
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
        
        let input = CityCameraViewModel.Input(
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            videoTrigger: videoTrigger.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
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
                    self?.videos = videos
                    if videos.isEmpty {
                        self?.button.setTitle("Запросить запись", for: .normal)
                        self?.button.backgroundColor = UIColor.SmartYard.blue
                        self?.button.titleColorForNormal = UIColor.white
                    } else {
                        self?.button.setTitle("Проишествия ("+String(self?.videos?.count ?? 0)+")", for: .normal)
                        self?.button.backgroundColor = UIColor.white
                        self?.button.titleColorForNormal = UIColor.SmartYard.blue
                    }
                    
                    
                }
            ).disposed(by: disposeBag)
        
        button.rx.tap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    self?.collectionView.isHidden = false
                    self?.collectionView.reloadData()
                    self?.toggleView()
                }
            
            )
            .disposed(by: disposeBag)
        
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
        //collectionView.register(YTCollectionViewCell.self, forCellWithReuseIdentifier: "YTCollectionViewCell")
    }
    /*
    private func configureCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        item: SettingsDataItem
    ) -> UICollectionViewCell {
        // swiftlint:disable:next closure_body_length
        let cell: UICollectionViewCell = { [weak self] in
            guard let self = self else {
                return UICollectionViewCell()
            }
            
            switch item {
            case let .header(_, title, subtitle, isExpanded):
                let cell = collectionView.dequeueReusableCell(withClass: SettingsHeaderCell.self, for: indexPath)
                cell.configure(title: title, subtitle: subtitle, isExpanded: isExpanded)
                return cell
                
            case let .controlPanel(identity, configuration):
                let cell = collectionView.dequeueReusableCell(withClass: SettingsControlPanelCell.self, for: indexPath)
                cell.configure(with: configuration)
                
                let subject = PublishSubject<SettingsServiceType>()
                
                subject
                    .map { input -> (SettingsDataItemIdentity, SettingsServiceType) in
                        (identity, input)
                    }
                    .bind(to: self.serviceButtonTapTrigger)
                    .disposed(by: cell.disposeBag)
                
                cell.bind(with: subject)
                
                return cell
                
            case let .action(identity):
                let cell = collectionView.dequeueReusableCell(withClass: SettingsActionCell.self, for: indexPath)
                
                if case let .action(_, type) = identity {
                    cell.configure(title: type.localizedTitle)
                }
                
                return cell
                
            case .addAddress:
                let cell = collectionView.dequeueReusableCell(withClass: SettingsAddAddressCell.self, for: indexPath)
                
                let subject = PublishSubject<Void>()
                
                subject
                    .bind(to: addAddressTrigger)
                    .disposed(by: cell.disposeBag)
                
                cell.bind(with: subject)
                
                return cell
            }
        }()
        
        guard let itemsCountDict = try? itemsCountProxy.value(),
            let totalItemsInSection = itemsCountDict[indexPath.section] else {
            return cell
        }
        
        let isFirstInSection = indexPath.row == 0
        let isLastInSection = indexPath.row == totalItemsInSection - 1
        
        (cell as? CustomBorderCollectionViewCell)?.addCustomBorder(
            isFirstInSection: isFirstInSection,
            isLastInSection: isLastInSection,
            customBorderWidth: 1,
            customBorderColor: UIColor.SmartYard.grayBorder,
            customCornerRadius: 12,
            separatorInset: 24
        )
        
        return cell
    }
*/
    
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
        guard let camera = camera else { return }
        
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
            isLast: collectionView.numberOfItems(inSection: 0) - 1 == indexPath.item
        )
        return cell
    }
}

extension CityCameraViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.view.width - 10 , height: 53)
    }
    
    func  collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
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
