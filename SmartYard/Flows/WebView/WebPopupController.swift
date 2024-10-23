//
//  WebPopupController.swift
//  SmartYard
//
//  Created by Александр Васильев on 16.12.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//
import UIKit
import WebKit
import RxSwift
import RxCocoa
import JGProgressHUD
import WKCookieWebView

enum TransitionType {
    case popup
    case push
    case replace
}

final class WebPopupController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var animatedView: UIView!
    
    @IBOutlet private var animatedViewBottomOffset: NSLayoutConstraint!
    @IBOutlet private var viewHeightConstraint: NSLayoutConstraint!
    
    private var swipeDismissInteractor: SwipeInteractionController?
    
    @IBOutlet private weak var webView: WKCookieWebView!
    @IBOutlet private weak var skeletonView: UIView!
    
    var loader: JGProgressHUD?
    
    private let viewModel: WebViewModel
    private let shareUrlTrigger = PublishSubject<URL>()
    
    /// (url: URL, newWindow: Bool)
    private let openUrlTrigger = PublishSubject<(URL, TransitionType)>()
    private var webContentHeight: CGFloat?
    private let accessToken: String
    
    private let version: Int
    
    init(viewModel: WebViewModel, accessToken: String = "", version: Int = 1) {
        self.viewModel = viewModel
        self.accessToken = accessToken
        self.version = version
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        swipeDismissInteractor?.animatedViewBottomOffset = animatedViewBottomOffset.constant
    }
    
    private func bind() {
        let input = WebViewModel.Input(
            viewWillAppearTrigger: rx.viewWillAppear.asDriver(),
            isViewVisible: rx.isVisible.asDriver(onErrorJustReturn: false),
            shareUrlTrigger: shareUrlTrigger.asDriverOnErrorJustComplete(),
            backTrigger: Observable<Void>.empty().asDriverOnErrorJustComplete(),
            openUrlTrigger: openUrlTrigger.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.loadURL
            .distinctUntilChanged()
            .drive(
                onNext: { [weak self] url in
                    self?.webView.load(URLRequest(url: url))
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
    
    fileprivate func removeUserContentController() {
        webView.configuration.userContentController.removeAllUserScripts()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "loadingStartedHandler")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "loadingFinishedHandler")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "refreshParentHandler")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "isAppInstalledHandler")
        
    }
    
    fileprivate func configureUserContentController() {
        webView.configuration.userContentController.add(self, name: "loadingStartedHandler")
        webView.configuration.userContentController.add(self, name: "loadingFinishedHandler")
        webView.configuration.userContentController.add(self, name: "refreshParentHandler")
        webView.configuration.userContentController.add(self, name: "isAppInstalledHandler")
        
        let javaScript = "bearerToken = function() { return \"" + accessToken + "\"; };"
        let script = WKUserScript(source: javaScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
        
        _ = {
            let javaScript = """
isAppInstalled = function(url, callbackFunc ) {
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.isAppInstalledHandler) {
            window.SmartYardWebExt_service_func = function (url, result) {
                callbackFunc(url, result);
            }
            window.webkit.messageHandlers.isAppInstalledHandler.postMessage({
                    "url": url, "callback": "window.SmartYardWebExt_service_func"
            });
        } };
"""
            let script = WKUserScript(source: javaScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            webView.configuration.userContentController.addUserScript(script)
        }()
    }
    
    private func configureView() {
        configureSwipeAction()
        configureRxKeyboard()
        view.backgroundColor = .clear
        webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 17, left: 0, bottom: 5, right: 0)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        configureUserContentController()
        configureGestures(with: 0)
    }
    
    private func configureSwipeAction() {
        swipeDismissInteractor = SwipeInteractionController(
            viewController: self,
            animatedView: animatedView,
            scrollView: webView.scrollView
        )
        
        swipeDismissInteractor?.animatedViewBottomOffset = animatedViewBottomOffset.constant
        swipeDismissInteractor?.velocityThreshold = 1500
        
        transitioningDelegate = self
    }
    
    private func configureRxKeyboard() {
        RxKeyboard.instance.visibleHeight
            .drive(
                onNext: { [weak self] keyboardHeight in
                    guard let self = self else {
                        return
                    }

                    self.configureGestures(with: keyboardHeight)
                    
                    let defaultBottomOffset: CGFloat = -50
                    let maxHeight = self.backgroundView.frame.height - 100
                    let webContentHeight = self.webContentHeight ?? 0
                    
                    // определяем, насколько мы можем безопасно подвинуть вверх
                    // наш popup-view, чтобы он не обрезался сверху
                    let maxOffset = maxHeight - webContentHeight > 0 ? maxHeight - webContentHeight : 0
                    
                    // определяем на сколько нам достаточно поднять вверх наш pop-up,
                    // чтобы он не перекрывался клавиатурой
                    let desiredOffset = keyboardHeight
                    
                    // окончательно определяем допустимое смещение, чтобы оно не превышало максимальное.
                    let calcOffset = desiredOffset <= maxOffset ? desiredOffset : maxOffset
                    
                    let offset = keyboardHeight == 0 ? 0 : calcOffset
                    
                    UIView.animate(
                        withDuration: 0.05,
                        animations: { [weak self] in
                            self?.animatedViewBottomOffset.constant = offset + defaultBottomOffset
                            self?.view.layoutIfNeeded()
                            
                            if keyboardHeight == 0 {
                                self?.webView.scrollView.contentOffset = .zero
                            }
                            
                        }
                    )
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func addDismissViewGesture() {
        let dismissViewTapGesture = UITapGestureRecognizer()
        backgroundView.addGestureRecognizer(dismissViewTapGesture)
        
        dismissViewTapGesture.rx.event
            .asDriver()
            .drive(
                onNext: { [weak self] _ in
                    self?.dismiss(
                        animated: true,
                        completion: {
                            self?.removeUserContentController()
                        }
                    )
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureGestures(with keyboardHeight: CGFloat) {
        view.gestureRecognizers?.removeAll()
        animatedView.gestureRecognizers?.removeAll()
        backgroundView.gestureRecognizers?.removeAll()
        
        switch keyboardHeight {
        case 0:
            self.addDismissViewGesture()
            self.configureSwipeAction()
        default:
            break
        }
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
    
    fileprivate func updateViewHeight(_ webView: WKWebView) {
        webView.evaluateJavaScript("document.documentElement.offsetHeight", completionHandler: { height, _ in
            guard let height = height as? CGFloat else {
                return
            }
            self.webContentHeight = height
            let maxHeight = self.backgroundView.frame.height - 100
            if height > maxHeight {
                self.viewHeightConstraint.constant = maxHeight + 50
                self.webView.scrollView.bounces = false
            } else {
                self.viewHeightConstraint.constant = height + 50
                self.webView.scrollView.bounces = false
            }
            
            self.animatedView.layoutIfNeeded()
        })
    }
}

extension WebPopupController: PickerAnimatable {
    
    var animatedBackgroundView: UIView { return backgroundView }
    
    var animatedMovingView: UIView { return animatedView }
    
}

extension WebPopupController: UIViewControllerTransitioningDelegate {
    
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
        return PickerPresentAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PickerDismissAnimator()
    }
    
    func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
        ) -> UIViewControllerInteractiveTransitioning? {
        guard let interactionInProgress = swipeDismissInteractor?.interactionInProgress else {
            return nil
        }
        return interactionInProgress ? swipeDismissInteractor : nil
    }
    
}
extension WebPopupController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: AnyObject] else {
            return
        }
        
        if message.name == "loadingFinishedHandler" {
            updateViewHeight(webView)
            self.updateLoader(isEnabled: false, detailText: nil)
            self.skeletonView.isHidden = true
        }
        
        if message.name == "loadingStartedHandler" {
            self.updateLoader(isEnabled: true, detailText: nil)
            self.skeletonView.isHidden = false
        }
        
        if message.name == "refreshParentHandler" {
            NotificationCenter.default.post(name: .refreshVisibleWebVC, object: nil, userInfo: dict)
        }
        
        if message.name == "isAppInstalledHandler" {
            let url = dict["url"] as? String
            let callbackName = dict["callback"] as? String
            guard let url = URL(string: url), let callbackName = callbackName else { return }
            let result = UIApplication.shared.canOpenURL(url)
            
            _ = {
                let javaScript = """
                \(callbackName)("\(url)", \(result));
    """
                webView.evaluateJavaScript(javaScript)
            }()
        }
    }
}

extension WebPopupController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // page starts loading - показать скелетон
        self.updateLoader(isEnabled: true, detailText: nil)
        self.skeletonView.isHidden = false
        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // page loaded - скрыть скелетон
        self.loader?.dismiss(animated: false)
        self.skeletonView.isHidden = true
        
        updateViewHeight(webView)
        
        // Disable WebView long press text selection box and enlarge box
        webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none';")
        webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none';")
        webView.allowsLinkPreview = false
        disableDragAndDropInteraction()
    }
    // swiftlint:disable:next function_body_length
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if version == 1 {
            guard [.linkActivated, .formSubmitted].contains(navigationAction.navigationType) else {
                decisionHandler(WKNavigationActionPolicy.allow)
                return
            }
            
            if let url = navigationAction.request.url {
                
                if url.relativeString.contains("#smart-yard-close") {
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    self.dismiss(animated: true)
                    return
                }
                
                let trigger = self.openUrlTrigger
                
                self.dismiss(
                    animated: true,
                    completion: {
                        if navigationAction.targetFrame != nil {
                            // делаем замену viewcontroller в navigation stack если target == текущее окно
                            trigger.onNext((url, .replace))
                            decisionHandler(WKNavigationActionPolicy.cancel)
                        } else {
                            // если target == новое окно, то открываем модально popup шторку
                            trigger.onNext((url, .popup))
                            decisionHandler(WKNavigationActionPolicy.cancel)
                        }
                    }
                )
                
            } else {
                decisionHandler(WKNavigationActionPolicy.allow)
            }
        } else {
            // version 2
            if [.reload].contains(navigationAction.navigationType) {
                decisionHandler(WKNavigationActionPolicy.allow)
                return
            }
            
            if let url = navigationAction.request.url {
                let trigger = self.openUrlTrigger
                
                print(url)
                
                // target = '_blank'
                if navigationAction.targetFrame == nil {
                    UIApplication.shared.open(url)
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
                }
                
                // #smart-yard-close
                if url.relativeString.contains("#smart-yard-close") {
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    self.dismiss(animated: true)
                    return
                }
                
                // #smart-yard-push
                if url.relativeString.contains("#smart-yard-push"),
                   let newUrl = URL(
                    string: url.absoluteString.replacingOccurrences(
                        ofPattern: "#smart-yard-push", withTemplate: ""
                    )
                   ) {
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    self.dismiss(
                        animated: true,
                        completion: {
                            trigger.onNext((newUrl, .push))
                        }
                    )
                    return
                }
                
                // #smart-yard-popup
                if url.relativeString.contains("#smart-yard-popup"),
                   let newUrl = URL(
                    string: url.absoluteString.replacingOccurrences(
                        ofPattern: "#smart-yard-popup", withTemplate: ""
                    )
                   ) {
                    // открываем модально другую popup шторку
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    self.dismiss(
                        animated: true,
                        completion: {
                            trigger.onNext((newUrl, .popup))
                        }
                    )
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
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    self.dismiss(
                        animated: true,
                        completion: {
                            trigger.onNext((newUrl, .replace))
                        }
                    )
                    return
                }
                // #smart-yard-external
                if url.relativeString.contains("#smart-yard-external"),
                   let newUrl = URL(
                    string: url.absoluteString.replacingOccurrences(
                        ofPattern: "#smart-yard-external", withTemplate: ""
                    )
                   ) {
                    // открываем в новом окне через системный вызов
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    self.dismiss(
                        animated: true,
                        completion: {
                            UIApplication.shared.open(newUrl)
                        }
                    )
                    return
                }
                
                // если это sberpay:, tel: или ещё какой-то кастомный дип-линк, то обрабатывыаем переход по умолчанию
                guard url.scheme == "https" || url.scheme == "http" else {
                    UIApplication.shared.open(url)
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
                }
            }
            
            decisionHandler(WKNavigationActionPolicy.allow)
        }
        
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let alert = UIAlertController(
            title: NSLocalizedString("Error", comment: ""),
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }
}
