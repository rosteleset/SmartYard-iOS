//
//  FullscreenPlayerViewController.swift
//  SmartYard
//
//  Created by admin on 30.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import AVKit
import RxSwift
import RxCocoa

class FullscreenPlayerViewController: UIViewController {
    
    enum PlayedVideoType {
        case online
        case archive
    }
    
    private let playedVideoType: PlayedVideoType
    private let preferredPlaybackRate: Float

    private var playerViewController: AVPlayerViewController?
    private var progressSlider: SimpleVideoProgressSlider?
    private var sliderConstraints: [NSLayoutConstraint] = []
    
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet weak var playPauseButton: UIButton!
    
    private var controls: [UIView] = []
    private var timer: Timer?
    
    private var disposeBag = DisposeBag()
    
    init(playedVideoType: PlayedVideoType, preferredPlaybackRate: Float) {
        self.playedVideoType = playedVideoType
        self.preferredPlaybackRate = preferredPlaybackRate
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction private func tapCloseButton() {
        self.playerViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapPlayPauseButton() {
        guard let player = self.playerViewController?.player else {
            return
        }
        
        let newState = !self.playPauseButton.isSelected
        self.playPauseButton.isSelected = newState
        
        player.rate = newState ? self.preferredPlaybackRate : 0
    }
    
    func onTimer(_ : Timer) {
        guard let progressSlider = self.progressSlider else {
            return
        }
        
        self.timer = nil
        
        guard progressSlider.isReceivingGesture else {
            self.hideControls()
            return
        }
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: onTimer)
    }
    
    @IBAction func tapView(_ sender: UITapGestureRecognizer) {
        
        guard self.timer != nil else {
            self.showControls()
            self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: onTimer)
            return
        }
        
        self.timer?.invalidate()
        self.hideControls()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard isBeingDismissed else {
            return
        }
        //возвращаем обратно AutoresizingMask и удаляем лишние Constraints, чтобы последующее возвращение контроллера на место прошло гладко
        playerViewController!.view!.removeConstraints(playerViewController!.view!.constraints)
        playerViewController!.view!.translatesAutoresizingMaskIntoConstraints = true
        
        if playedVideoType == .archive {
            progressSlider?.removeConstraints(sliderConstraints)
            self.timer?.invalidate()
            progressSlider?.isHidden = false
            
        }
        
        switch playedVideoType {
        case .online: NotificationCenter.default.post(name: .onlineFullscreenModeClosed, object: nil)
        case .archive: NotificationCenter.default.post(name: .archiveFullscreenModeClosed, object: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIViewController.attemptRotationToDeviceOrientation()
        
        if self.timer == nil {
            self.showControls()
            self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: onTimer)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        playerViewController?.view.frame = contentView.bounds
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.scrollView.zoomScale = 1.0
        self.scrollView.contentSize = size
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //добавляем в контейнер дочерний контроллер плеера, добавляем во вью плеер и настраиваем его отображение
        addChild(playerViewController!)
        contentView.removeSubviews()
        contentView.insertSubview(playerViewController!.view!, at: 0)
        playerViewController!.didMove(toParent: self)
        playerViewController?.view.translatesAutoresizingMaskIntoConstraints = false
        playerViewController!.view!.removeConstraints(playerViewController!.view!.constraints)
        playerViewController?.view.fillToSuperview()
        
        guard playedVideoType == .archive else {
            return
        }
        
        //добавляем во вью progressSlider и настраиваем его отображение
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
        
        playPauseButton.isSelected = ((playerViewController?.player!.rate)! > 0)
        
        controls = []
        controls.append(progressSlider)
        controls.append(playPauseButton)
        
        hideControls()
    }
    
    @IBAction private func  debug() {
        self.playerViewController?.view.frame = UIScreen.main.bounds
    }
    
    func setPlayerViewController(_ playerViewController: AVPlayerViewController) {
        
        self.playerViewController = playerViewController
        playerViewController.showsPlaybackControls = false
        
        disposeBag = DisposeBag()
        
        guard let player = playerViewController.player else {
            return
        }
        
        player.rx
            .observe(Float.self, "rate", options: [.new])
            .observeOn(MainScheduler.asyncInstance)
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
                        self.playerViewController?.player?.rate = self.preferredPlaybackRate
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    func setProgressSlider(_ progressSlider: SimpleVideoProgressSlider) {
        self.progressSlider = progressSlider
    }

}
extension FullscreenPlayerViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.contentView
    }
}
extension FullscreenPlayerViewController {
    private func showControls () {
        controls.map({ $0.isHidden = false })
    }
    
    private func hideControls () {
        controls.map({ $0.isHidden = true })
    }
}
