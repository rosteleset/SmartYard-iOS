//
//  NotificationsViewController.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import UIKit
import RxSwift
import RxCocoa
import WebKit
import JGProgressHUD
import WKCookieWebView

class WebViewIntercomController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var webView: WKCookieWebView!
    @IBOutlet private weak var skeletonView: UIView!

    var loader: JGProgressHUD?
    private var refreshControl = UIRefreshControl()
    
    private let viewModel: WebViewIntercomModel
    private let shareUrlTrigger = PublishSubject<URL>()
    
    /// (url: URL, backLabelString: String, newWindow: Bool)
    private let openUrlTrigger = PublishSubject<(URL, String, TransitionType)>()
    public let successStatusLoaded = BehaviorSubject(value: false)

    private var titleString = ""
    private var webContentHeight: CGFloat?
    private let accessToken: String
    
    private var refreshDisposable: Disposable?
    private let refreshSubject = PublishSubject<Void>()
    
    init(
        viewModel: WebViewIntercomModel,
        accessToken: String = ""
    ) {
        self.viewModel = viewModel
        self.accessToken = accessToken
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        bind()
        subscribeToEventsUpdateNotifications()
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
        
//        refreshDisposable = NotificationCenter.default.rx.notification(.refreshVisibleWebVC)
//            .asDriverOnErrorJustComplete()
//            .drive(
//                onNext: { [weak self] notification in
//                    let timeout = notification.userInfo?["timeout"] as? Double ?? 0.0
//
//                    DispatchQueue.main.asyncAfter(delay: timeout) {
//                        self?.refreshSubject.onNext(())
//                    }
//                }
//            )
//
//        refreshDisposable?.disposed(by: disposeBag)
        
        super.viewWillAppear(animated)
    }
    
    fileprivate func disableDragAndDropInteraction() {
        var webScrollView: UIView?
        var contentView: UIView?
        
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
    
    fileprivate func configureUserContentController() {
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        webView.configuration.userContentController.add(self, name: "loadingStartedHandler")
        webView.configuration.userContentController.add(self, name: "loadingFinishedHandler")

        let javaScript = "bearerToken = function() { return \"" + accessToken + "\"; };"
        
        let script = WKUserScript(source: javaScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
        
        if #available(iOS 13.0,*) {
            let validator = CertificateValidator()
            Task {
                let names = ["Russian Trusted Root CA", "Russian Trusted Sub CA"]
                await validator.prepareCertificates(names)
            }
        }
    }
    
    @objc func gotoHomeURL() {
        guard let url = self.viewModel.getUrl() else {
            return
        }
        self.webView.loadURL(url)
    }
    
    private func configureView() {
//        skeletonView.layerCornerRadius = 24
//        skeletonView.layer.maskedCorners = .topCorners
//        webView.layerCornerRadius = 24
//        webView.layer.maskedCorners = .topCorners

        webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 17, left: 0, bottom: 5, right: 0)
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.bounces = true
        webView.scrollView.refreshControl = refreshControl
        #if DEBUG
            if #available(iOS 16.4, *) {
                webView.isInspectable = true
            }
        #endif
        configureUserContentController()
        subscribeToAddressUpdateNotifications()
    }
    
    private func bind() {
        let input = WebViewIntercomModel.Input(
            viewWillAppearTrigger: rx.viewWillAppear.asDriver(),
            isViewVisible: rx.isVisible.asDriver(onErrorJustReturn: false),
            shareUrlTrigger: shareUrlTrigger.asDriverOnErrorJustComplete(),
//            backTrigger: fakeNavBar.rx.backButtonTap.asDriver(),
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
        
//        output.loadContent
//            .drive(
//                onNext: { [weak self] args in
//                    let (content, baseURL) = args
//
//                    self?.webView.loadHTMLString(content, baseURL: URL(string: baseURL))
//                }
//            )
//            .disposed(by: disposeBag)
        
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
        
        Observable
            .merge(
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
    }
    
    private func subscribeToEventsUpdateNotifications() {
        NotificationCenter.default.rx.notification(.resendPushToJS)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] notification in
                    guard let self = self,
                          let userInfo = notification.userInfo,
                          let javascript = userInfo["yard"] as? String else {
                        return
                    }
                    self.webView.evaluateJavaScript(javascript) { (result, error) in
                        if let error = error {
                            print("ERROR EVAL JS", error)
                        } else if let result = result {
                            print("SUCCESS EVAL JS", result)
                        }
                    }
                }
            )
            .disposed(by: disposeBag)
    }

    private func subscribeToAddressUpdateNotifications() {
        NotificationCenter.default.rx.notification(.addressAdded)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.viewModel.getListAddress()
                    self.viewModel.getOptions()
                    self.webView.reload()
                }
            )
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.addressNeedUpdate)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.webView.reload()
                }
            )
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.addressDeleted)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.viewModel.getListAddress()
                    self.viewModel.getOptions()
                    self.webView.reload()
                }
            )
            .disposed(by: disposeBag)

    }

}

extension WebViewIntercomController: WKScriptMessageHandler {
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

extension WebViewIntercomController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // page starts loading - показать скелетон
        self.updateLoader(isEnabled: true, detailText: nil)
        self.skeletonView.isHidden = false
        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // page loaded - скрыть скелетон если код ответа меньше 400
        self.successStatusLoaded
            .asDriver(onErrorJustReturn: false)
            .isTrue()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    
                    self.updateLoader(isEnabled: false, detailText: nil)
                    self.refreshControl.endRefreshing()
                    self.skeletonView.isHidden = true
                }
            )
            .disposed(by: disposeBag)
        
        disableDragAndDropInteraction()
        
        // self.titleString = webView.title ?? ""
        // увы webView.title возвращает пустую строку, когда страница повторно загружается,
        // поэтому приходится костылить через JS
        webView.evaluateJavaScript("document.title", completionHandler: { title, _ in
            self.titleString = title as? String ?? ""
        })
        
        webView.evaluateJavaScript("document.documentElement.offsetHeight", completionHandler: { height, _ in
            self.webContentHeight = height as? CGFloat
        })
    }
    
    func webView(_
                 webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        guard let statusCode = (navigationResponse.response as? HTTPURLResponse)?.statusCode else {
            decisionHandler(.allow)
            return
        }
        switch statusCode {
        case 400..<500:
            self.updateLoader(isEnabled: true, detailText: nil)
            self.skeletonView.isHidden = false
            self.successStatusLoaded.onNext(false)
            print("WEBVIEW ERROR", statusCode)
            DispatchQueue.main.asyncAfter(delay: 5.0) {
                self.webView.reload()
            }
            
        case 500..<600:
            self.updateLoader(isEnabled: true, detailText: nil)
            self.skeletonView.isHidden = false
            self.successStatusLoaded.onNext(false)
            print("WEBVIEW ERROR", statusCode)
            DispatchQueue.main.asyncAfter(delay: 5.0) {
                self.webView.reload()
            }
            
        default:
            self.successStatusLoaded.onNext(true)
        }
        
        decisionHandler(.allow)
    }
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
//        print("DEBUG URL:", navigationAction.request, self.viewModel.getUrl())
//        if navigationAction.request.url == webView.url {
//            self.fakeNavBar.isHidden = true
//        } else {
//            self.fakeNavBar.isHidden = false
//        }
        
        if let uq = navigationAction.request.url?.absoluteString,
           let hq = uq.firstIndex(of: "#"),
           let qs = uq.firstIndex(of: "?"){
            let query = String(uq[uq.index(after: qs)..<uq.endIndex]).components(separatedBy: "&")
            var qe: [String : String] = [:]
            for elm in query {
                let pair = elm.components(separatedBy: "=")
                qe[pair[0]] = pair[1]
            }
            
            switch qe["type"] {
            case "conf":
//                self.fakeNavBar.isHidden = true
                decisionHandler(WKNavigationActionPolicy.cancel)
                guard let clientId = qe["clientId"] else {
                    return
                }
                self.viewModel.router.trigger(.accessService(address: qe["address"]?.removingPercentEncoding ?? "", flatId: qe["flatId"] ?? "", clientId: clientId))
                return
            case "events":
//                self.fakeNavBar.isHidden = true
                decisionHandler(WKNavigationActionPolicy.cancel)
                guard let houseId = qe["houseId"] else {
                    return
                }
                self.viewModel.router.trigger(.historyEvents(houseId: houseId, address: qe["address"]?.removingPercentEncoding ?? ""))
                return
            case "map":
                decisionHandler(WKNavigationActionPolicy.cancel)
                guard let houseId = qe["houseId"] else {
                    return
                }
                self.viewModel.router.trigger(.homeCamera(houseId: "", camId: nil))
//                self.viewModel.router.trigger(.homeCameras(houseId: qe["houseId"] ?? "", address: qe["address"]?.removingPercentEncoding ?? ""))
                return
            case "fullscreen":
                decisionHandler(WKNavigationActionPolicy.cancel)
                guard let cam = qe["camId"],
                      let camId = Int(cam),
                      let houseId = qe["houseId"] else {
                    return
                }
//                print("CAMID", qe)\

                self.viewModel.router.trigger(.homeCamera(houseId: "", camId: camId))

//                if #available(iOS 15.0, *) {
//                    self.viewModel.router.trigger(.fullscreenarchive(camId: camId))
//                } else {
//                    self.viewModel.router.trigger(.fullscreen(camId: camId, houseId: houseId))
//                }
                return
            case "addContract":
                decisionHandler(WKNavigationActionPolicy.cancel)
//                self.viewModel.router.trigger(.inputContract(isManualTrigger: true))
                return
            default:
                break
            }
        }
        
        guard [.linkActivated, .formSubmitted].contains(navigationAction.navigationType) else {
            decisionHandler(WKNavigationActionPolicy.allow)
            return
        }
        
        if let url = navigationAction.request.url {
//            print(url)

            // если это sberpay или ещё какой-то кастомный дип-линк, то обрабатывыаем переход по умолчанию
            guard url.scheme == "https" || url.scheme == "http" else {
                UIApplication.shared.open(url)
                decisionHandler(WKNavigationActionPolicy.cancel)
                return
            }
            
            // если это страницы, которые не хостятся у нас, то делаем обычный переход по ссылке.
            guard let host = url.host, host.hasPrefix("lk-demo.mycentra.ru") else {
                      decisionHandler(WKNavigationActionPolicy.allow)
                      return
                  }
            
            if navigationAction.targetFrame != nil {
                // делаем push в navigation stack если target == текущее окно
                self.openUrlTrigger.onNext((url, titleString, .push))
                decisionHandler(WKNavigationActionPolicy.cancel)
                return
            } else {
                // если target == новое окно, то открываем модально popup шторку
                self.openUrlTrigger.onNext((url, "В начало", .popup))
                decisionHandler(WKNavigationActionPolicy.cancel)
                return
            }
        }
        
        decisionHandler(WKNavigationActionPolicy.cancel)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            return completionHandler(.performDefaultHandling, nil)
        }
        
        if #available(iOS 13.0,*) {
            let validator = CertificateValidator()
            Task.detached(priority: .userInitiated) {
                if await validator.checkValidity(of: serverTrust) {
                    let cred = URLCredential(trust: serverTrust)
                    completionHandler(.useCredential, cred)
                } else {
                    completionHandler(.performDefaultHandling, nil)
                }
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
}

// swiftlint:enable function_body_length
