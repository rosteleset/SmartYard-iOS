//
//  SharedWebKit.swift
//  SmartYard
//
//  Created by Александр Попов on 03.10.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import WebKit

enum SharedWebKit {
    static let processPool = WKProcessPool()

    static let warmWebView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.processPool = processPool
        config.websiteDataStore = .default()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.isHidden = true
        wv.load(URLRequest(url: URL(string: "about:blank")!))
        return wv
    }()
}
