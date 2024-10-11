//
//  NotificationsViewController.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import WebKit
import JGProgressHUD

class NotificationsHomeViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!

    var loader: JGProgressHUD?
    
    private let viewModel: NotificationsHomeViewModel
    
    private let shareUrlTrigger = PublishSubject<URL>()
    
    init(viewModel: NotificationsHomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fakeNavBar.configueBlueNavBar()
        configureView()
        bind()
    }
    
    private func configureView() {
//        webView.layerCornerRadius = 24
//        webView.layer.maskedCorners = .topCorners
        
        webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 17, left: 0, bottom: 5, right: 0)
        webView.navigationDelegate = self
    }
    
    private func bind() {
        let input = NotificationsHomeViewModel.Input(
            viewWillAppearTrigger: rx.viewWillAppear.asDriver(),
            isViewVisible: rx.isVisible.asDriver(onErrorJustReturn: false),
            shareUrlTrigger: shareUrlTrigger.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.inboxResponse
            .distinctUntilChanged()
            .drive(
                onNext: { [weak self] response in
                    guard let response = response, let url = URL(string: response.basePath) else {
                        return
                    }
                    
                    self?.webView.loadHTMLString(response.code, baseURL: url)
                }
            )
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
    }

}

extension NotificationsHomeViewController: WKNavigationDelegate {
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard navigationAction.navigationType == .linkActivated else {
            decisionHandler(WKNavigationActionPolicy.allow)
            return
        }
        
        if let url = navigationAction.request.url {
            if url.absoluteString.starts(with: "https://cam.mycentra.ru/files/") {
                shareUrlTrigger.onNext(url)
            } else {
                UIApplication.shared.open(url)
            }
        }
        
        decisionHandler(WKNavigationActionPolicy.cancel)
    }
    
}
