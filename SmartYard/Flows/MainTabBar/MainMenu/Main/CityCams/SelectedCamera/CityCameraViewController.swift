//
//  CityMapViewController.swift
//  SmartYard
//
//  Created by Александр Васильев on 14.02.2021.
//  Copyright © 2021 Sesameware. All rights reserved.

import UIKit
import JGProgressHUD
import RxSwift
import RxCocoa
import RxDataSources
import AVKit
import Lottie

// swiftlint:disable:next type_body_length
final class CityCameraViewController: BaseViewController {
    enum ButtonState {
        case initial, incidents, requestRec
    }
    enum ViewState {
        case normal, compact
    }
    //
    @IBOutlet private(set) var cameraNameConstraints: [NSLayoutConstraint]!
    //
    @IBOutlet private(set) var cameraNameConstraintsMini: [NSLayoutConstraint]!
    
    @IBOutlet private(set) weak var cameraName: UILabel!
    @IBOutlet private(set) weak var cameraAddress: UILabel!
    @IBOutlet private(set) weak var cameraContainer: UIView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private(set) weak var fullscreenButton: UIButton!
    @IBOutlet private(set) weak var videoLoadingAnimationView: LottieAnimationView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var skeletonContainer: UIView!
    @IBOutlet private(set) weak var button: UIButton!
    @IBOutlet private weak var gradientView: UIView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private(set) weak var soundToggleButton: UIButton!
    
    var camera: CityCameraObject?
    var videos: [YouTubeVideo]?
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    
    var viewState: ViewState = .normal
    var buttonState: ButtonState = .initial
    var loadingAsset: AVAsset?
    
    let isVideoValid = BehaviorSubject<Bool>(value: false)
    let isVideoBeingLoaded = BehaviorSubject<Bool>(value: false)
    private let videoTrigger = PublishSubject<String>()
    private let requestRecordTrigger = PublishSubject<Void>()
    let isSoundOn = BehaviorSubject<Bool>(value: false)
    
    var hasSound = false
    
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
    fileprivate func configureUI() {
        cameraAddress.text = L10n.Camera.City.Detail.addressPlaceholder
        cameraName.text = L10n.Camera.City.Detail.title
        cameraName.adjustsFontSizeToFitWidth = true
        cameraName.minimumScaleFactor = 0.65
        cameraName.allowsDefaultTighteningForTruncation = true
        cameraName.baselineAdjustment = .alignCenters
        fakeNavBar.setText(L10n.Camera.City.mapTitle)
        guard let camera = camera else {
            return
        }
        
        // Устанавливаем название камеры и её адрес
        let cameraTitle = splitCameraTitle(camera.name)
        
        cameraName.text = cameraTitle.name
        cameraAddress.text = cameraTitle.address
        
        // настраиваем градиент между кнопкой и CollectionView
        let gradientBackgroundColors = [UIColor.SmartYard.secondBackgroundColor.cgColor, UIColor.SmartYard.secondBackgroundColor.withAlphaComponent(0).cgColor]
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientBackgroundColors
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.locations = [0.0, 1.0]

        gradientLayer.frame = gradientView.bounds
        gradientView.layer.addSublayer(gradientLayer)
    }

    private func splitCameraTitle(_ title: String) -> (name: String, address: String) {
        let separators: [Character] = ["/", "|"]

        for separator in separators {
            let components = title
                .split(separator: separator, maxSplits: 1, omittingEmptySubsequences: true)
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

            if components.count == 2 {
                return (components[0], components[1])
            }
        }

        return (title, "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        bind()
    }
    
    fileprivate func toggleView() {
        if viewState == .normal {
            UIView.animate(
                withDuration: 0.5,
                animations: {
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
       
        // по нажатию на кнопку переключаем вид (у кнопки по мере переключений будет 2 разных действия)
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
                        
                        self.button.setTitle(L10n.Camera.City.requestRecordButton, for: .normal)
                        self.button.backgroundColor = UIColor.SmartYard.blue
                        self.button.setTitleColor(UIColor.SmartYard.secondBackgroundColor, for: .normal)
                        
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
                            self.button.setTitle(L10n.Camera.City.requestRecordButton, for: .normal)
                            self.button.backgroundColor = UIColor.SmartYard.blue
                            self.button.setTitleColor(UIColor.SmartYard.secondBackgroundColor, for: .normal)
                            self.buttonState = .requestRec
                            
                        } else {
                            self.button.setTitle(
                                "\(L10n.Camera.City.incidentsTitle) (" + String(self.videos?.count ?? 0) + ")",
                                for: .normal
                            )
                            self.button.backgroundColor = UIColor.SmartYard.secondBackgroundColor
                            self.button.setTitleColor(UIColor.SmartYard.blue, for: .normal)
                            self.buttonState = .incidents
                        }
                    } 
                }
            )
            .disposed(by: disposeBag)
        
        // Загружаем камеру и инициализируем воспроизведение
        self.camera = output.camera
        configureUI()
        configurePlayer()
        configureFullscreenButton()
        configureSoundToggleButton()
        loadVideo()
    }
    
    deinit {
        player?.replaceCurrentItem(with: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }
    
    private func configureCollectionView() {
   
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(nibWithCellClass: YTCollectionViewCell.self)
        collectionView.refreshControl = refreshControl
        collectionView.isHidden = true // по умолчанию не показываем список до нажатия на кнопку Проишествия
    }
    
}

extension CityCameraViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos?.count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: YTCollectionViewCell.self, for: indexPath)
        
        cell.configureCell(
            label: self.videos?[indexPath.item].title ?? "",
            thumbnailUrl: self.videos?[indexPath.item].thumbnailsDefault,
            isFirst: indexPath.item == 0
        )
        return cell
    }
}

extension CityCameraViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: collectionView.view.width - 16, height: 100)
    }
    
    func  collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
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
