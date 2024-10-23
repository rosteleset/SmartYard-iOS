//
//  LoadingButton.swift
//  SmartYard
//
//  Created by admin on 18/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

final class LoadingButton: UIButton {
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        activityIndicator.style = .whiteLarge
        
        self.addSubview(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.anchorCenterSuperview()
        
        return activityIndicator
    }()
    
    func showLoading() {
        isEnabled = false
        activityIndicator.startAnimating()
    }
    
    func hideLoading() {
        activityIndicator.stopAnimating()
        isEnabled = true
    }
    
}
