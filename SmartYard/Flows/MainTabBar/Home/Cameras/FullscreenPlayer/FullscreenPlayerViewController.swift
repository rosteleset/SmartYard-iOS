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

    private var playerViewController: AVPlayerViewController?
    
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
