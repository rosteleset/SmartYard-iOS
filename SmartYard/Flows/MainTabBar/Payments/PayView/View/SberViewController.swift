//
//  SberViewController.swift
//  SmartYard
//
//  Created by devcentra on 14.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import WebKit

class SberViewController: UIViewController {
    
    let webView = WKWebView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
    }
}
