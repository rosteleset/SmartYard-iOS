//
//  PaymentsCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import XCoordinator
import SafariServices
import RxSwift
import RxCocoa

enum PaymentsRoute: Route {
    
    case main
    case alert(title: String, message: String)
    case contractPay(address: String, items: [APIPaymentsListAccount])
    case back
    case safariPage(url: URL)
    
    case paymentPopup(
        apiWrapper: APIWrapper,
        clientId: String,
        recommendedSum: Double?,
        constracNumber: String?
    )
    
}

class PaymentsCoordinator: NavigationCoordinator<PaymentsRoute> {
    
    private let disposeBag = DisposeBag()
    
    let apiWrapper: APIWrapper
    
    init(
        apiWrapper: APIWrapper
    ) {
        self.apiWrapper = apiWrapper
        super.init(initialRoute: .main)
        rootViewController.setNavigationBarHidden(true, animated: false)
        subscribeToPaymentsNotifications()
    }
    
    override func prepareTransition(for route: PaymentsRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = PaymentsViewModel(apiWrapper: apiWrapper, router: weakRouter)
            let vc = PaymentsViewController(viewModel: vm)
            return .set([vc])
            
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case let .contractPay(address, items):
            let vm = PayContractViewModel(
                address: address,
                items: items,
                apiWrapper: apiWrapper,
                router: weakRouter
            )
            
            let vc = PayContractViewController(viewModel: vm)
            return .push(vc)
            
        case .back:
            return .pop(animation: .default)
            
        case let .paymentPopup(apiWrapper, clientId, recommendedSum, contractNumber):
            let vm = PaymentPopupViewModel(
                apiWrapper: apiWrapper,
                clientId: clientId,
                recommendedSum: recommendedSum,
                contractNumber: contractNumber
            )
            
            let vc = PaymentPopupController(viewModel: vm)
            
            vc.modalPresentationStyle = .overFullScreen
            
            return .present(vc)
            
        case let .safariPage(url):
            let vc = SFSafariViewController(url: url)
            return .present(vc)
        }
    }
    
    private func subscribeToPaymentsNotifications() {
        NotificationCenter.default.rx.notification(.paymentCompleted)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    // MARK: Если в стеке уже есть PaymentsViewController - ничего делать не надо
                    guard !(self.rootViewController.viewControllers.contains {
                        $0 is PaymentsViewController
                    }) else {
                        return
                    }
                    
                    // MARK: Если его нет в стеке - принудительно возвращаем юзера на главный экран
                    self.trigger(.main)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
