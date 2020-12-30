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
    private var scrollView: UIScrollView!
    
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard isBeingDismissed else {
            return
        }
        
        switch playedVideoType {
        case .online: NotificationCenter.default.post(name: .onlineFullscreenModeClosed, object: nil)
        case .archive: NotificationCenter.default.post(name: .archiveFullscreenModeClosed, object: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        playerViewController?.view.frame = UIScreen.main.bounds
    }
    
    func setPlayerViewController(_ playerViewController: AVPlayerViewController) {
        view.removeSubviews()
        
        self.playerViewController = playerViewController
        
        addChild(playerViewController)
        view.insertSubview(playerViewController.view, at: 0)
        playerViewController.didMove(toParent: self)
        
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

}
