//
//  FullscreenPlayerViewController.swift
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

class FullscreenPlayerViewController: UIViewController, LoaderPresentable {
    
    enum PlayedVideoType {
        case online
        case archive
        case city
    }
    
    private let playedVideoType: PlayedVideoType
    private let preferredPlaybackRate: Float
    private let doors: [DoorObject]
    private let position: CGRect?

    private weak var playerLayer: AVPlayerLayer?
    private var progressSlider: SimpleVideoProgressSlider?
    private var sliderConstraints: [NSLayoutConstraint] = []

    private let apiWrapper: APIWrapper?
    private let activityTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var muteButton: UIButton!
    @IBOutlet private weak var openButtonsCollection: UIView!
    
    @IBOutlet private weak var openButton1View: UIView!
    @IBOutlet private weak var openButton2View: UIView!
    @IBOutlet private weak var openButton3View: UIView!
    @IBOutlet private weak var openButton1: CameraLockButton!
    @IBOutlet private weak var openButton2: CameraLockButton!
    @IBOutlet private weak var openButton3: CameraLockButton!
    @IBOutlet private weak var textButton1: UILabel!
    @IBOutlet private weak var textButton2: UILabel!
    @IBOutlet private weak var textButton3: UILabel!

    private var controls: [UIView] = []
    private var timer: Timer?
    
    var loader: JGProgressHUD?

    private var disposeBag = DisposeBag()
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .default
//        return .lightContent
//    }

    init(
        playedVideoType: PlayedVideoType,
        preferredPlaybackRate: Float,
        position: CGRect? = nil,
        doors: [DoorObject] = [],
        apiWrapper: APIWrapper? = nil
    ) {
        self.playedVideoType = playedVideoType
        self.preferredPlaybackRate = preferredPlaybackRate
        self.doors = doors
        self.apiWrapper = apiWrapper
        self.position = position
        
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
        // чтобы корректно отработала анимация и не было конфликта в ходе анимации за эту переходящую вьюшку,
        // убираем её из иерархии до запуска анимации закрытия окна.
//        progressSlider?.removeFromSuperview()
//
//        self.dismiss(animated: true, completion: nil)
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
        guard let progressSlider = self.progressSlider else {
            return
        }
        
        guard progressSlider.isReceivingGesture else {
            self.hideControls()
            return
        }
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: onTimer)
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
    
    @IBAction private func doubleTap(_ sender: UITapGestureRecognizer) {
        
        guard playedVideoType == .archive,
              let player = self.playerLayer?.player else {
            return
        }
        
        var offset = 0
        
        if sender.location(in: view).x < view.width / 2 - 10 {
            offset = -15
        }
        
        if sender.location(in: view).x > view.width / 2 + 10 {
            offset = 15
        }
        
        if offset == 0 {
            return
        }
        
        player.seek(offset)
        
        let label = (offset > 0) ? UILabel(text: "+\(abs(offset)) сек") : UILabel(text: "-\(abs(offset)) сек")
        label.font = UIFont(name: "System", size: 16)
        label.font = label.font.bold
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: 0, width: 100, height: 21)
        label.center = CGPoint(x: view.width * ((offset > 0) ? 3 : 1) / 4, y: view.height / 2)
        label.textColor = .white
        label.backgroundColor = .clear
        view.addSubview(label)
        
        UIView.animate(
            withDuration: 1.5,
            animations: {
                label.alpha = 0
            },
            completion: { _ in
                label.removeFromSuperview()
            }
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard isBeingDismissed else {
            return
        }
        
        if playedVideoType == .archive {
            progressSlider?.removeConstraints(sliderConstraints)
            self.timer?.invalidate()
            self.timer = nil
            progressSlider?.isHidden = false
        }
        switch playedVideoType {
        case .online: NotificationCenter.default.post(name: .onlineFullscreenModeClosed, object: nil)
        case .archive: NotificationCenter.default.post(name: .archiveFullscreenModeClosed, object: nil)
        case .city: NotificationCenter.default.post(name: .cityFullscreenModeClosed, object: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if playedVideoType == .online, !doors.isEmpty {
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
      
        bind()
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        
        if playedVideoType == .online {
            switch doors.count {
            case 1:
                openButtonsCollection.isHidden = false
                openButton1View.isHidden = false
                openButton2View.isHidden = true
                openButton3View.isHidden = true
                textButton1.text = doors[0].name
                openButton1.setImage(UIImage(named: doors[0].type), for: .normal)
            case 2:
                openButtonsCollection.isHidden = false
                openButton1View.isHidden = true
                openButton2View.isHidden = false
                openButton3View.isHidden = false
                textButton2.text = doors[0].name
                openButton1.setImage(UIImage(named: doors[0].type), for: .normal)
                textButton3.text = doors[1].name
                openButton1.setImage(UIImage(named: doors[1].type), for: .normal)
            case 3:
                openButtonsCollection.isHidden = false
                openButton1View.isHidden = false
                openButton2View.isHidden = false
                openButton3View.isHidden = false
                textButton1.text = doors[0].name
                openButton1.setImage(UIImage(named: doors[0].type), for: .normal)
                textButton2.text = doors[1].name
                openButton1.setImage(UIImage(named: doors[1].type), for: .normal)
                textButton3.text = doors[2].name
                openButton1.setImage(UIImage(named: doors[2].type), for: .normal)
            default:
                openButtonsCollection.isHidden = true
            }
        } else {
            openButtonsCollection.isHidden = true
        }
        
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
        
        if let playerLayer = playerLayer {
           contentView.layer.insertSublayer(playerLayer, at: 0)
        }
        
        if playedVideoType == .city {
            muteButton.isHidden = true
        }
        
        guard playedVideoType == .archive else {
            return
        }
        
        // добавляем во вью progressSlider и настраиваем его отображение
        guard let progressSlider = self.progressSlider else {
            return
        }
        view.addSubview(progressSlider)
        sliderConstraints = []
        sliderConstraints.append(progressSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12))
        sliderConstraints.append(progressSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12))
        sliderConstraints.append(progressSlider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16))
        for constraint in sliderConstraints {
            constraint.isActive = true
        }
        
        playPauseButton.isSelected = ((playerLayer?.player!.rate)! > 0)
        
        controls = []
        controls.append(progressSlider)
        controls.append(playPauseButton)
        
        hideControls()
    }
    
    @objc private dynamic func handleSwipeGestureRecognizer(_ recognizer: UISwipeGestureRecognizer) {

        animatedClose()
//        if recognizer.direction == .left {
//            UIView.animate(
//                withDuration: 0.5,
//                delay: 0.0,
//                options: .curveEaseOut,
//                animations: {
//                    self.contentView.frame.origin.x -= self.contentView.frame.size.width
//                    self.contentView.alpha = 0.0
//                },
//                completion: { _ in
//                    self.dismiss(animated: true, completion: nil)
//                }
//            )
//        }
    }

    private func animatedClose() {
        progressSlider?.removeFromSuperview()
        muteButton.isHidden = true
        closeButton.isHidden = true
        playPauseButton.isHidden = true
        openButtonsCollection.isHidden = true
        self.scrollView.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
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
        
//        errorTracker
//            .asDriver()
//            .drive(
//                onNext: { [weak self] _ in
//                }
//            )
//            .disposed(by: disposeBag)
    }
    
    func setProgressSlider(_ progressSlider: SimpleVideoProgressSlider) {
        self.progressSlider = progressSlider
    }

    func setMuteButton(icon: String) {
        self.muteButton.setImage(UIImage(named: icon), for: .normal)
        self.muteButton.setImage(UIImage(named: icon)?.darkened(), for: [.normal, .highlighted])
    }
}

extension FullscreenPlayerViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.contentView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
}

extension FullscreenPlayerViewController {
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
