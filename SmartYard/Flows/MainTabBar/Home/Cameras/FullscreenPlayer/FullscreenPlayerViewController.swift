//
//  FullscreenPlayerViewController.swift
//  SmartYard
//
//  Created by admin on 30.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
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

    private weak var playerLayer: AVPlayerLayer?
    private var progressSlider: SimpleVideoProgressSlider?
    private var sliderConstraints: [NSLayoutConstraint] = []
    
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var playPauseButton: UIButton!
    
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
        // чтобы корректно отработала анимация и не было конфликта в ходе анимации за эту переходящую вьюшку,
        // убираем её из иерархии до запуска анимации закрытия окна.
        progressSlider?.removeFromSuperview()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func tapPlayPauseButton() {
        guard let player = self.playerLayer?.player else {
            return
        }
        
        let newState = !self.playPauseButton.isSelected
        self.playPauseButton.isSelected = newState
        
        player.rate = newState ? self.preferredPlaybackRate : 0
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
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }
        
        if self.timer == nil {
            self.showControls()
            self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: onTimer)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        playerLayer?.frame = contentView.bounds
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.scrollView.zoomScale = 1.0
        self.scrollView.contentSize = size
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        if let playerLayer = playerLayer {
           contentView.layer.insertSublayer(playerLayer, at: 0)
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
        controls.forEach({ $0.isHidden = false })
    }
    
    private func hideControls () {
        controls.forEach({ $0.isHidden = true })
    }
}
