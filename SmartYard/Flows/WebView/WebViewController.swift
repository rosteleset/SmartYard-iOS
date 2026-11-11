//
//  NotificationsViewController.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import WebKit
import JGProgressHUD
import WKCookieWebView
import SwifterSwift
import SnapKit

final class WebViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var webView: WKCookieWebView!
    @IBOutlet private(set) weak var skeletonView: UIView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    @IBOutlet private weak var webViewTopToFakeNavBarConstraint: NSLayoutConstraint?
    @IBOutlet private weak var webViewTopToSafeAreaConstraint: NSLayoutConstraint?
    @IBOutlet private weak var skeletonTopToFakeNavBarConstraint: NSLayoutConstraint?
    @IBOutlet private weak var skeletonTopToSafeAreaConstraint: NSLayoutConstraint?
    
    var loader: JGProgressHUD?
    var refreshControl = UIRefreshControl()
    
    private let viewModel: WebViewModel
    let backButtonLabel: String
    private let shareUrlTrigger = PublishSubject<URL>()
    
    /// (url: URL, newWindow: Bool)
    let openUrlTrigger = PublishSubject<(URL, TransitionType)>()
    
    var documentTitle = ""
    var webContentHeight: CGFloat?
    private let accessToken: String
    
    private var refreshDisposable: Disposable?
    private let refreshSubject = PublishSubject<Void>()
    
    let version: Int
    private let enableRefreshControl: Bool
    private let webViewOptions: APIExtension.WebViewOptions?
    var pageControlsLoadingState = false
    
    init(
        viewModel: WebViewModel,
        backButtonLabel: String = L10n.Common.back,
        accessToken: String = "",
        version: Int,
        refreshControl: Bool = true,
        webViewOptions: APIExtension.WebViewOptions? = nil
    ) {
        self.viewModel = viewModel
        self.backButtonLabel = backButtonLabel
        self.accessToken = accessToken
        self.version = version
        self.enableRefreshControl = refreshControl
        self.webViewOptions = webViewOptions
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = webViewOptions?.tabBarHidden == true
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        switch webViewOptions?.statusBarStyle {
        case .light:
            return .lightContent
        case .dark:
            return .darkContent
        case .none:
            return .default
        }
    }

    override var prefersStatusBarHidden: Bool {
        webViewOptions?.navBarHidden == true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        bind()

        registerForTraitChanges(
            UITraitCollection.systemTraitsAffectingColorAppearance,
            action: #selector(handleColorAppearanceChange)
        )
    }
    
    fileprivate func removeUserContentController() {
        webView.configuration.userContentController.removeAllUserScripts()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "loadingStartedHandler")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "loadingFinishedHandler")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "isAppInstalledHandler")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "backHandler")
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

    @objc private func handleColorAppearanceChange() {
        webView.notifySmartYardThemeChanged()
    }
    
    func disableDragAndDropInteraction() {
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
        webView.configuration.userContentController.add(self, name: "loadingStartedHandler")
        webView.configuration.userContentController.add(self, name: "loadingFinishedHandler")
        webView.configuration.userContentController.add(self, name: "isAppInstalledHandler")
        webView.configuration.userContentController.add(self, name: "backHandler")
        webView.configuration.userContentController.addUserScript(makeLocaleBridgeScript())
        webView.configuration.userContentController.addUserScript(makeZoomLockScript())
        webView.addSmartYardThemeBridgeScript()
        
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

    private func configureUI() {
        let isNavBarHidden = webViewOptions?.navBarHidden == true
        let shouldShowFakeNavBar = !backButtonLabel.isEmpty && !isNavBarHidden
        let shouldExtendUnderTabBar = webViewOptions?.extendsUnderTabBar == true

        if shouldExtendUnderTabBar {
            edgesForExtendedLayout.insert(.bottom)
            extendedLayoutIncludesOpaqueBars = true
            webView.scrollView.contentInset = .zero
            webView.scrollView.scrollIndicatorInsets = .zero
        }

        fakeNavBar.configueDarkNavBar()
        fakeNavBar.configure(
            backgroundColor: webViewOptions?.navBarColor.flatMap { UIColor(hexString: $0) },
            contentColor: webViewOptions?.navBarContentColor.flatMap { UIColor(hexString: $0) }
        )
        fakeNavBar.setText(backButtonLabel)
        fakeNavBar.isHidden = !shouldShowFakeNavBar
        view.backgroundColor = webViewOptions?.statusBarColor.flatMap { UIColor(hexString: $0) }
            ?? UIColor.SmartYard.backgroundColor

        webViewTopToFakeNavBarConstraint?.isActive = shouldShowFakeNavBar && !isNavBarHidden
        skeletonTopToFakeNavBarConstraint?.isActive = shouldShowFakeNavBar && !isNavBarHidden
        webViewTopToSafeAreaConstraint?.isActive = !shouldShowFakeNavBar && !isNavBarHidden
        skeletonTopToSafeAreaConstraint?.isActive = !shouldShowFakeNavBar && !isNavBarHidden

        if isNavBarHidden {
            webView.snp.makeConstraints { make in
                make.top.equalToSuperview()
            }
            skeletonView.snp.makeConstraints { make in
                make.top.equalToSuperview()
            }
        }

        webView.scrollView.contentInsetAdjustmentBehavior = isNavBarHidden || shouldExtendUnderTabBar
            ? .never
            : .automatic
        webView.scrollView.scrollIndicatorInsets = .zero
        disableWebViewZoom()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        let isPullToRefreshEnabled = enableRefreshControl && webViewOptions?.pullToRefreshEnabled != false
        webView.scrollView.refreshControl = isPullToRefreshEnabled ? refreshControl : nil
        configureUserContentController()
        bindThemeBridge()
        
    }

    func disableWebViewZoom() {
        webView.scrollView.minimumZoomScale = 1
        webView.scrollView.maximumZoomScale = 1
        webView.scrollView.zoomScale = 1
        webView.scrollView.bouncesZoom = false
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        disableDoubleTapRecognizers(in: webView)
    }

    private func disableDoubleTapRecognizers(in view: UIView) {
        view.gestureRecognizers?
            .compactMap { $0 as? UITapGestureRecognizer }
            .filter { $0.numberOfTapsRequired > 1 }
            .forEach { $0.isEnabled = false }

        view.subviews.forEach(disableDoubleTapRecognizers)
    }

    private func bindThemeBridge() {
        ThemeManager.shared.currentTheme
            .distinctUntilChanged()
            .skip(1)
            .subscribe(with: self) { owner, _ in
                owner.webView.notifySmartYardThemeChanged()
            }
            .disposed(by: disposeBag)
    }

}

extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "backHandler" {
            navigationController?.popViewController(animated: true)
            return
        }

        guard let dict = message.body as? [String: AnyObject] else {
            return
        }

        if message.name == "loadingFinishedHandler" {
            self.updateLoader(isEnabled: false, detailText: nil)
            self.skeletonView.isHidden = true
        }

        if message.name == "loadingStartedHandler" {
            self.pageControlsLoadingState = true
            self.updateLoader(isEnabled: true, detailText: nil)
            self.skeletonView.isHidden = false
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

extension WebViewController {

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

        bindRefresh(output.isLoading)

        fakeNavBar.rx.backButtonTap
            .asDriver()
            .drive(
                onNext: { [weak self] in
                    self?.removeUserContentController()
                }
            )
            .disposed(by: disposeBag)

    }

    private func bindRefresh(_ isLoading: Driver<Bool>) {
        isLoading
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
    }
}

private extension WebViewController {
    func makeLocaleBridgeScript() -> WKUserScript {
        let locale = Bundle.main.preferredLocalizations.first
            ?? Locale.preferredLanguages.first
            ?? "ru"
        let encodedLocale = (try? JSONSerialization.data(withJSONObject: [locale]))
            .flatMap { String(data: $0, encoding: .utf8) }
            .flatMap { value -> String? in
                guard value.count >= 2 else { return nil }
                return String(value.dropFirst().dropLast())
            }
            ?? "\"ru\""
        let source = "window.smartYardLocale = \(encodedLocale);"

        return WKUserScript(
            source: source,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
    }

    func makeZoomLockScript() -> WKUserScript {
        let source = """
        (function () {
            var viewportContent = "width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover";

            function lockViewport() {
                var root = document.head || document.documentElement;
                if (!root) {
                    return;
                }

                var viewports = document.querySelectorAll('meta[name="viewport"]');
                var viewport = viewports.length ? viewports[0] : null;
                if (!viewport) {
                    viewport = document.createElement("meta");
                    viewport.name = "viewport";
                    root.appendChild(viewport);
                }
                viewport.setAttribute("content", viewportContent);
                for (var index = 1; index < viewports.length; index += 1) {
                    viewports[index].remove();
                }

                var style = document.getElementById("smart-yard-disable-webview-zoom");
                if (!style) {
                    style = document.createElement("style");
                    style.id = "smart-yard-disable-webview-zoom";
                    style.textContent = "html, body { touch-action: pan-x pan-y !important; } button, a, input, textarea, select, label, [role='button'] { touch-action: manipulation !important; }";
                    root.appendChild(style);
                }
            }

            function preventZoom(event) {
                event.preventDefault();
            }

            lockViewport();
            document.addEventListener("DOMContentLoaded", lockViewport, { once: true });
            document.addEventListener("gesturestart", preventZoom, { passive: false });
            document.addEventListener("gesturechange", preventZoom, { passive: false });
            document.addEventListener("gestureend", preventZoom, { passive: false });
        }());
        """

        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }
}
