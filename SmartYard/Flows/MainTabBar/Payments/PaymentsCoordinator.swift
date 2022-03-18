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
//    case contractPay(address: String, items: [APIPaymentsListAccount])
    case contractPay(index: Int, items: [APIPaymentsListAddress])
    case back
    case dismiss
    case dismissAndOpen(url: URL)
    case safariPage(url: URL)
    case webView(url: URL)
    
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
            
        case let .contractPay(index, items):
            let vm = PayContractViewModel(
                index: index,
                items: items,
                apiWrapper: apiWrapper,
                router: weakRouter
            )
            
            if items.count == 1 { //если выбор адреса из одного элемента, то пропускаем его
                let vc = PayContractViewController(viewModel: vm, hideNavBar: true)
                return .set([vc])
            } else {
                let vc = PayContractViewController(viewModel: vm, hideNavBar: false)
                return .push(vc)
            }
            
        case .back:
            return .pop(animation: .default)
            
        case .dismiss:
            return .dismiss(animation: .default)
            
        case let .dismissAndOpen(url):
            trigger(.dismiss) { [weak self] in
                self?.trigger(.safariPage(url: url))
            }
            return .none()
            
        case let .paymentPopup(apiWrapper, clientId, recommendedSum, contractNumber):
            let vm = PaymentPopupViewModel(
                apiWrapper: apiWrapper,
                clientId: clientId,
                recommendedSum: recommendedSum,
                contractNumber: contractNumber,
                router: weakRouter
            )
            
            let vc = PaymentPopupController(viewModel: vm)
            
            vc.modalPresentationStyle = .overFullScreen
            
            return .present(vc)
            
        case let .safariPage(url):
            let vc = SFSafariViewController(url: url)
            return .present(vc)
            
        case let .webView(url):
            let coordinator = WebViewCoordinator(
                rootVC: rootViewController,
                apiWrapper: apiWrapper,
                url: url,
                backButtonLabel: "Назад",
                push: true
            )
            
            addChild(coordinator)
            return .none()
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
