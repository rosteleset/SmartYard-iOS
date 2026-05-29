//
//  SharedWebKit.swift
//  SmartYard
//
//  Created by Александр Попов on 03.10.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit
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

// Contract for embedded pages:
// - Read the initial theme from window.SmartYardTheme.getTheme() or
//   document.documentElement.dataset.smartyardTheme.
// - Listen to the "smartyard:themeChanged" window event. event.detail.theme is
//   "light" or "dark"; event.detail.isDark is a convenience boolean.
// - Apply the page palette and color-scheme from that value. The app sends the
//   event at document start and again whenever the native theme changes.
enum WebViewThemeBridge {
    static let eventName = "smartyard:themeChanged"

    static func addUserScript(to webView: WKWebView) {
        let script = WKUserScript(
            source: setupJavaScript(themeName: themeName(for: webView)),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        webView.configuration.userContentController.addUserScript(script)
    }

    static func notifyThemeChanged(in webView: WKWebView) {
        webView.evaluateJavaScript(themeUpdateJavaScript(themeName: themeName(for: webView))) { _, error in
            if let error {
                Logger.logWarning(
                    "Не удалось отправить тему в WKWebView: \(error.localizedDescription)"
                )
            }
        }
    }

    private static func themeName(for view: UIView) -> String {
        switch ThemeManager.shared.currentTheme.value {
        case .dark:
            return "dark"
        case .light:
            return "light"
        case .unspecified:
            return view.traitCollection.userInterfaceStyle == .dark ? "dark" : "light"
        @unknown default:
            Logger.logWarning(
                "Unknown ThemeManager style encountered: \(ThemeManager.shared.currentTheme.value)"
            )
            return view.traitCollection.userInterfaceStyle == .dark ? "dark" : "light"
        }
    }

    private static func setupJavaScript(themeName: String) -> String {
        """
        (function() {
            window.SmartYardTheme = window.SmartYardTheme || {};
            window.SmartYardTheme.eventName = "\(eventName)";
            window.SmartYardTheme.setTheme = function(theme) {
                window.SmartYardTheme.current = theme;

                if (document.documentElement) {
                    document.documentElement.setAttribute('data-smartyard-theme', theme);
                    document.documentElement.style.colorScheme = theme;
                }

                var detail = { theme: theme, isDark: theme === 'dark' };
                var event;

                if (typeof CustomEvent === 'function') {
                    event = new CustomEvent('\(eventName)', { detail: detail });
                } else {
                    event = document.createEvent('CustomEvent');
                    event.initCustomEvent('\(eventName)', false, false, detail);
                }

                window.dispatchEvent(event);
            };
            window.SmartYardTheme.getTheme = function() {
                return window.SmartYardTheme.current;
            };
            window.SmartYardTheme.setTheme("\(themeName)");
        })();
        """
    }

    private static func themeUpdateJavaScript(themeName: String) -> String {
        """
        (function() {
            if (window.SmartYardTheme && typeof window.SmartYardTheme.setTheme === 'function') {
                window.SmartYardTheme.setTheme("\(themeName)");
            }
        })();
        """
    }
}

extension WKWebView {
    func addSmartYardThemeBridgeScript() {
        WebViewThemeBridge.addUserScript(to: self)
    }

    func notifySmartYardThemeChanged() {
        WebViewThemeBridge.notifyThemeChanged(in: self)
    }
}
