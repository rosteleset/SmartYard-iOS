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
import WKCookieWebView

class WebViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var webView: WKCookieWebView!
    @IBOutlet private weak var skeletonView: UIView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    var loader: JGProgressHUD?
    private var refreshControl = UIRefreshControl()
    
    private let viewModel: WebViewModel
    private let backButtonLabel: String
    private let shareUrlTrigger = PublishSubject<URL>()
    
    /// (url: URL, newWindow: Bool)
    private let openUrlTrigger = PublishSubject<(URL, TransitionType)>()
    
    var documentTitle = ""
    private var webContentHeight: CGFloat?
    private let accessToken: String
    
    private var refreshDisposable: Disposable?
    private let refreshSubject = PublishSubject<Void>()
    
    private let version: Int
    
    init(
        viewModel: WebViewModel,
        backButtonLabel: String = "Назад",
        accessToken: String = "",
        version: Int
    ) {
        self.viewModel = viewModel
        self.backButtonLabel = backButtonLabel
        self.accessToken = accessToken
        self.version = version
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        bind()
    }
    
    fileprivate func removeUserContentController() {
        webView.configuration.userContentController.removeAllUserScripts()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "loadingStartedHandler")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "loadingFinishedHandler")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // removeUserContentController()
        
        refreshDisposable?.dispose()
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // configureUserContentController()
        refreshDisposable = NotificationCenter.default.rx.notification(.refreshVisibleWebVC)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] notification in
                    let timeout = notification.userInfo?["timeout"] as? Double ?? 0.0
                    
                    DispatchQueue.main.asyncAfter(delay: timeout) {
                        self?.refreshSubject.onNext(())
                    }
                }
            )
            
        refreshDisposable?.disposed(by: disposeBag)
        super.viewWillAppear(animated)
    }
    
    fileprivate func disableDragAndDropInteraction() {
        var webScrollView: UIView?
        var contentView: UIView?
        
        if #available(iOS 11.0, *) {
            guard let noDragWebView = webView else {
                return
            }
            webScrollView = noDragWebView.subviews.compactMap { $0 as? UIScrollView }.first
            contentView = webScrollView?.subviews.first(where: { $0.interactions.count > 1 })
            guard let dragInteraction = (contentView?.interactions.compactMap { $0 as? UIDragInteraction }.first) else {
                return
            }
            contentView?.removeInteraction(dragInteraction)
        }
    }
    
    fileprivate func configureUserContentController() {
        webView.configuration.userContentController.add(self, name: "loadingStartedHandler")
        webView.configuration.userContentController.add(self, name: "loadingFinishedHandler")
        
        let javaScript = "bearerToken = function() { return \"" + accessToken + "\"; };"
        let script = WKUserScript(source: javaScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
    }
    
    private func configureView() {
        fakeNavBar.configueDarkNavBar()
        fakeNavBar.setText(backButtonLabel)
        if backButtonLabel.isEmpty {
            fakeNavBar.isHidden = true
        }
        webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 17, left: 0, bottom: 5, right: 0)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.refreshControl = refreshControl
        configureUserContentController()
        
    }
    
    private func bind() {
        let input = WebViewModel.Input(
            viewWillAppearTrigger: rx.viewWillAppear.asDriver(),
            isViewVisible: rx.isVisible.asDriver(onErrorJustReturn: false),
            shareUrlTrigger: shareUrlTrigger.asDriverOnErrorJustComplete(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
            openUrlTrigger: openUrlTrigger.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.loadURL
            .drive(
                onNext: { [weak self] url in
                    self?.webView.load(URLRequest(url: url))
                }
            )
            .disposed(by: disposeBag)
        
        output.loadContent
            .drive(
                onNext: { [weak self] args in
                    let (content, baseURL) = args
                    
                    self?.webView.loadHTMLString(content, baseURL: URL(string: baseURL))
                }
            )
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                    if !isLoading {
                        self?.refreshControl.endRefreshing()
                    }
                }
            )
            .disposed(by: disposeBag)
        
        Observable.merge(
            refreshControl.rx.controlEvent(.valueChanged).mapToVoid(),
            refreshSubject
        )
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] in
                    self?.webView.reload()
                }
            )
            .disposed(by: disposeBag)
        
        fakeNavBar.rx.backButtonTap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    self?.removeUserContentController()
                }
            )
            .disposed(by: disposeBag)

    }

}
extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
//        guard let dict = message.body as? [String: AnyObject] else {
//            return
//        }
        
        if message.name == "loadingFinishedHandler" {
            self.updateLoader(isEnabled: false, detailText: nil)
            self.skeletonView.isHidden = true
        }
        
        if message.name == "loadingStartedHandler" {
            self.updateLoader(isEnabled: true, detailText: nil)
            self.skeletonView.isHidden = false
        }
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // page starts loading - показать скелетон
        self.updateLoader(isEnabled: true, detailText: nil)
        self.skeletonView.isHidden = false
        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // page loaded - скрыть скелетон
        self.updateLoader(isEnabled: false, detailText: nil)
        self.refreshControl.endRefreshing()
        self.skeletonView.isHidden = true
        disableDragAndDropInteraction()
        
        // self.titleString = webView.title ?? self.backButtonLabel
        // увы webView.title возвращает пустую строку, когда страница повторно загружается,
        // поэтому приходится костылить через JS
        webView.evaluateJavaScript("document.title", completionHandler: { title, _ in
            self.documentTitle = title as? String ?? self.backButtonLabel
        })
        
        webView.evaluateJavaScript("document.documentElement.offsetHeight", completionHandler: { height, _ in
            self.webContentHeight = height as? CGFloat
        })
    }
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if version == 1 {
            guard [.linkActivated, .formSubmitted, .other].contains(navigationAction.navigationType) else {
                decisionHandler(WKNavigationActionPolicy.allow)
                return
            }
            
            if let url = navigationAction.request.url {
                print(url)
                // если это sberpay:, tel: или ещё какой-то кастомный дип-линк, то обрабатывыаем переход по умолчанию
                guard url.scheme == "https" || url.scheme == "http" else {
                    UIApplication.shared.open(url)
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
                }
                
                // если это страницы, которые хостятся на внешнем хосте, то открываем в новом окне.
                guard let host = url.host, let currentUrl = webView.url, host == currentUrl.host else {
                    UIApplication.shared.open(url)
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
                }
                
                // это редиректы не на внешние сайты.
                if navigationAction.navigationType == .other {
                    decisionHandler(WKNavigationActionPolicy.allow)
                    return
                }
                
                if navigationAction.targetFrame != nil {
                    // делаем push в navigation stack если target == текущее окно
                    self.openUrlTrigger.onNext((url, .push))
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
                } else {
                    // если target == новое окно, то открываем модально popup шторку
                    self.openUrlTrigger.onNext((url, .popup))
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
                }
            }
            
            decisionHandler(WKNavigationActionPolicy.cancel)
        } else {
            if [.reload].contains(navigationAction.navigationType) {
                decisionHandler(WKNavigationActionPolicy.allow)
                return
            }
            
            if let url = navigationAction.request.url {
                print(url)
                print(navigationAction.navigationType.rawValue)
                // #smart-yard-push
                if url.relativeString.contains("#smart-yard-push"),
                   let newUrl = URL(
                    string: url.absoluteString.replacingOccurrences(
                        ofPattern: "#smart-yard-push", withTemplate: ""
                    )
                   )
                {
                    // делаем push в navigation stack если target == текущее окно
                    self.openUrlTrigger.onNext((newUrl, .push))
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
                }
                // #smart-yard-popup
                if url.relativeString.contains("#smart-yard-popup"),
                   let newUrl = URL(
                    string: url.absoluteString.replacingOccurrences(
                        ofPattern: "#smart-yard-popup", withTemplate: ""
                    )
                   ) {
                    // открываем модально popup шторку
                    self.openUrlTrigger.onNext((newUrl, .popup))
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
                }
                // #smart-yard-replace
                if url.relativeString.contains("#smart-yard-replace"),
                   let newUrl = URL(
                    string: url.absoluteString.replacingOccurrences(
                        ofPattern: "#smart-yard-replace", withTemplate: ""
                    )
                   ) {
                    // заменяем текущий контроллер
                    self.openUrlTrigger.onNext((newUrl, .replace))
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
                }
                // #smart-yard-external
                if url.relativeString.contains("#smart-yard-external"),
                   let newUrl = URL(
                    string: url.absoluteString.replacingOccurrences(
                        ofPattern: "#smart-yard-external",
                        withTemplate: ""
                    )
                   ) {
                    // открываем в новом окне через системный вызов
                    UIApplication.shared.open(newUrl)
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
                }
                
                // если это sberpay:, tel: или ещё какой-то кастомный дип-линк, то обрабатывыаем переход по умолчанию
                guard url.scheme == "https" || url.scheme == "http" else {
                    UIApplication.shared.open(url)
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
                }
                
                if navigationAction.targetFrame == nil {
                    // если target == новое окно, то открываем в окне браузера
                    UIApplication.shared.open(url)
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
                }
            }
            
            decisionHandler(WKNavigationActionPolicy.allow)
        }
    }
    
}

extension BaseViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel) { _ in
            completionHandler()
        }
        
        alert.addAction(okAction)
        
        self.present(alert, animated: true)
    }
    
    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        }
        
        let calcelAction = UIAlertAction(title: "Отмена", style: .cancel) { _ in
            completionHandler(false)
        }
        
        alert.addAction(okAction)
        alert.addAction(calcelAction)
        
        self.present(alert, animated: true)
    }
    
    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let alert = UIAlertController(title: "", message: prompt, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            guard let textField = alert.textFields?.first else {
                return
            }
            completionHandler(textField.text)
        }
        
        let calcelAction = UIAlertAction(title: "Отмена", style: .cancel) { _ in
            completionHandler(nil)
        }
        
        alert.addTextField {textField in
            textField.text = defaultText
        }
        alert.addAction(okAction)
        alert.addAction(calcelAction)
        
        self.present(alert, animated: true)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        print("createWebView!")
        return nil
    }
}
