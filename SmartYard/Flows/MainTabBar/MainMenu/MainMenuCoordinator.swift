//
//  PaymentsCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 LanTa. All rights reserved.
//

import XCoordinator
import SafariServices
import RxSwift
import RxCocoa

enum MainMenuRoute: Route {
    
    case main
    case alert(title: String, message: String)
    case back
    case safariPage(url: URL)
}

class MainMenuCoordinator: NavigationCoordinator<MainMenuRoute> {
    
    private let disposeBag = DisposeBag()
    
    let apiWrapper: APIWrapper
    
    init(
        apiWrapper: APIWrapper
    ) {
        self.apiWrapper = apiWrapper
        super.init(initialRoute: .main)
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: MainMenuRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = MainMenuViewModel(apiWrapper: apiWrapper, router: weakRouter)
            let vc = MainMenuViewController(viewModel: vm)
            return .set([vc])
            
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case .back:
            return .pop(animation: .default)
            
        case let .safariPage(url):
            let vc = SFSafariViewController(url: url)
            return .present(vc)
        }
    }
}
