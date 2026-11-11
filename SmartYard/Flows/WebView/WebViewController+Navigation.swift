// Created by Александр Попов. Copyright © 2026 Sesameware.

import UIKit
import RxSwift
import RxCocoa
import WebKit
import JGProgressHUD
import WKCookieWebView
import SwifterSwift
import SnapKit

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // page starts loading - показать скелетон
        self.pageControlsLoadingState = false
        self.updateLoader(isEnabled: true, detailText: nil)
        self.skeletonView.isHidden = false

    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // page loaded - скрыть скелетон
        self.refreshControl.endRefreshing()
        if !self.pageControlsLoadingState {
            self.updateLoader(isEnabled: false, detailText: nil)
            self.skeletonView.isHidden = true
        }
        disableDragAndDropInteraction()
        disableWebViewZoom()

        // self.titleString = webView.title ?? self.backButtonLabel
        // увы webView.title возвращает пустую строку, когда страница повторно загружается,
        // поэтому приходится костылить через JS
        webView.evaluateJavaScript("document.title", completionHandler: { title, _ in
            self.documentTitle = title as? String ?? self.backButtonLabel
        })

        webView.evaluateJavaScript("document.documentElement.offsetHeight", completionHandler: { height, _ in
            self.webContentHeight = height as? CGFloat
        })
        webView.notifySmartYardThemeChanged()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if version == 1 {
            decideLegacyNavigation(navigationAction, in: webView, decisionHandler: decisionHandler)
        } else {
            decideNavigation(navigationAction, decisionHandler: decisionHandler)
        }
    }

    private func decideLegacyNavigation(
        _ navigationAction: WKNavigationAction,
        in webView: WKWebView,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard [.linkActivated, .formSubmitted, .other].contains(navigationAction.navigationType) else {
            decisionHandler(WKNavigationActionPolicy.allow)
            return
        }

        if let url = navigationAction.request.url {
            Logger.logDebug("WKWebView request URL: \(url.absoluteString)")
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
    }

    private func decideNavigation(
        _ navigationAction: WKNavigationAction,
        decisionHandler: (WKNavigationActionPolicy) -> Void
    ) {
        guard navigationAction.navigationType != .reload, let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        Logger.logDebug("WKWebView request URL: \(url.absoluteString)")

        if let transition = url.smartYardTransition {
            openUrlTrigger.onNext(transition)
            decisionHandler(.cancel)
            return
        }
        if let externalURL = url.removingWebViewMarker("#smart-yard-external") {
            UIApplication.shared.open(externalURL)
            decisionHandler(.cancel)
            return
        }
        guard url.scheme == "https" || url.scheme == "http", navigationAction.targetFrame != nil else {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let alert = UIAlertController(
            title: L10n.Common.error,
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(okAction)
        self.present(alert, animated: true)
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

        let calcelAction = UIAlertAction(title: L10n.Common.cancel, style: .cancel) { _ in
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

        let calcelAction = UIAlertAction(title: L10n.Common.cancel, style: .cancel) { _ in
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
        Logger.logInfo("createWebView!")
        return nil
    }
}
