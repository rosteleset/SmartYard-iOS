//
//  BaseViewController.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController, HasDisposeBag {

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        (self as? AnalyticsScreenTrackable)?.trackAnalyticsScreenOpened()
    }
}
