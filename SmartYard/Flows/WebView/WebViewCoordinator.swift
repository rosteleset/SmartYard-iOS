//
//  WebViewCoordinator.swift
//  SmartYard
//
//  Created by Александр Васильев on 05.02.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

import XCoordinator
import RxSwift
import RxCocoa

enum WebViewRoute: Route {
    case alert(title: String, message: String?)
    case dialog(title: String, message: String?, actions: [UIAlertAction])
    case back
    case dismiss
    case webView(url: URL, push: Bool, refreshControl: Bool = true)
    case webViewFromContent(content: String, baseURL: String, push: Bool, refreshControl: Bool = true)
    case webViewPopup(url: URL)
}

final class WebViewCoordinator: NavigationCoordinator<WebViewRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let apiWrapper: APIWrapper
    
    private let version: Int
    
    private let backButtonLabel: String
    
    init(
        rootVC: UINavigationController,
        apiWrapper: APIWrapper,
        url: URL,
        backButtonLabel: String,
        push: Bool,
        version: Int, // = 2
        refreshControl: Bool = true
    ) {
        self.apiWrapper = apiWrapper
        self.version = version
        self.backButtonLabel = backButtonLabel
        super.init(rootViewController: rootVC, initialRoute: nil)
        trigger(.webView(url: url, push: push, refreshControl: refreshControl))
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    init(
        rootVC: UINavigationController,
        apiWrapper: APIWrapper,
        content: String,
        baseURL: String,
        backButtonLabel: String,
        push: Bool,
        version: Int, // = 2
        refreshControl: Bool = true
    ) {
        self.apiWrapper = apiWrapper
        self.version = version
        self.backButtonLabel = backButtonLabel
        super.init(rootViewController: rootVC, initialRoute: nil)
        trigger(.webViewFromContent(content: content, baseURL: baseURL, push: push, refreshControl: refreshControl))
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    // подсмотрел это идею в Issue Tracker XCoordinator - этот финт решает проблему утечки памяти,
    // когда этот координатор добавляют дочерним.
    override var viewController: UIViewController! {
            rootViewController.viewControllers.first { $0 is WebViewController }
    }
    
    override func prepareTransition(for route: WebViewRoute) -> NavigationTransition {
        switch route {
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case let .dialog(title, message, actions):
            return .dialogTransition(title: title, message: message, actions: actions)
            
        case .back:
            return .pop(animation: .default)
            
        case .dismiss:
            return .dismiss()
            
        case let .webView(url, push, refreshControl):
            let vm = WebViewModel(
                apiWrapper: apiWrapper,
                router: weakRouter,
                url: url
            )
            
            let nc = rootViewController
            if !push {
                nc.popViewController(animated: false)
            }
            let topVc = nc.visibleViewController as? WebViewController
        
            let vc = WebViewController(
                viewModel: vm,
                backButtonLabel: topVc?.documentTitle ?? backButtonLabel,
                accessToken: apiWrapper.accessService.accessToken ?? "",
                version: version,
                refreshControl: refreshControl
            )
            
            return .push(vc)
        case let .webViewFromContent(content, baseURL, push, refreshControl):
            let vm = WebViewModel(
                apiWrapper: apiWrapper,
                router: weakRouter,
                content: content,
                baseURL: baseURL
            )
            
            let nc = rootViewController
            if !push {
                nc.popViewController(animated: false)
            }
            let topVc = nc.visibleViewController as? WebViewController
        
            let vc = WebViewController(
                viewModel: vm,
                backButtonLabel: topVc?.documentTitle ?? backButtonLabel,
                accessToken: apiWrapper.accessService.accessToken ?? "",
                version: version,
                refreshControl: refreshControl
            )
            return .push(vc)
            
        case let .webViewPopup(url):
            let vm = WebViewModel(
                apiWrapper: apiWrapper,
                router: weakRouter,
                url: url
            )
            
            let vc = WebPopupController(
                viewModel: vm,
                accessToken: apiWrapper.accessService.accessToken ?? "",
                version: version
            )
            vc.modalPresentationStyle = .overFullScreen
            
            return .present(vc)
        }
    }
}

