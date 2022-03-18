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
    case webView(url: URL, backButtonLabel: String, push: Bool)
    case webViewFromContent(content: String, baseURL: String, backButtonLabel: String, push: Bool)
    case webViewPopup(url: URL, backButtonLabel: String)
}

class WebViewCoordinator: NavigationCoordinator<WebViewRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let apiWrapper: APIWrapper
    
    init(
        rootVC: UINavigationController,
        apiWrapper: APIWrapper,
        url: URL,
        backButtonLabel: String,
        push: Bool
    ) {
        self.apiWrapper = apiWrapper
        super.init(rootViewController: rootVC, initialRoute: nil)
        trigger(.webView(url: url, backButtonLabel: backButtonLabel, push: push))
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    init(
        rootVC: UINavigationController,
        apiWrapper: APIWrapper,
        content: String,
        baseURL: String,
        backButtonLabel: String,
        push: Bool
    ) {
        self.apiWrapper = apiWrapper
        super.init(rootViewController: rootVC, initialRoute: nil)
        trigger(.webViewFromContent(content: content, baseURL: baseURL, backButtonLabel: backButtonLabel, push: push))
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
            
        case let .webView(url, backButtonLabel, push):
            let vm = WebViewModel(
                apiWrapper: apiWrapper,
                router: weakRouter,
                url: url
            )
            
            let vc = WebViewController(
                viewModel: vm,
                backButtonLabel: backButtonLabel,
                accessToken: apiWrapper.accessService.accessToken ?? ""
            )
            if push {
                return .push(vc)
            } else {
                let nc = rootViewController
                nc.popViewController(animated: false)
                
                return .push(vc)
            }
            
        case let .webViewFromContent(content, baseURL, backButtonLabel, push):
            let vm = WebViewModel(
                apiWrapper: apiWrapper,
                router: weakRouter,
                content: content,
                baseURL: baseURL
            )
            
            let vc = WebViewController(
                viewModel: vm,
                backButtonLabel: backButtonLabel,
                accessToken: apiWrapper.accessService.accessToken ?? ""
            )
            if push {
                return .push(vc)
            } else {
                let nc = rootViewController
                nc.popViewController(animated: false)
                
                return .push(vc)
            }
            
        case let .webViewPopup(url, backButtonLabel):
            let vm = WebViewModel(
                apiWrapper: apiWrapper,
                router: weakRouter,
                url: url
            )
            
            let vc = WebPopupController(
                viewModel: vm,
                backButtonLabel: backButtonLabel,
                accessToken: apiWrapper.accessService.accessToken ?? ""
            )
            vc.modalPresentationStyle = .overFullScreen
            
            return .present(vc)
        }
    }
}

