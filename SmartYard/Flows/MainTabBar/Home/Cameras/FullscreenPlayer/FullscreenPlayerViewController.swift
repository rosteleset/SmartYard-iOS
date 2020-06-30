//
//  FullscreenPlayerViewController.swift
//  SmartYard
//
//  Created by admin on 30.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import AVKit

class FullscreenPlayerViewController: UIViewController {
    
    enum PlayedVideoType {
        case online
        case archive
    }
    
    private let playedVideoType: PlayedVideoType

    private var playerViewController: AVPlayerViewController?
    
    init(playedVideoType: PlayedVideoType) {
        self.playedVideoType = playedVideoType
        
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
    }

}
