//
//  ChatwootViewModel.swift
//  SmartYard
//
//  Created by devcentra on 20.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class ChatwootViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    private let automaticMessage = PublishSubject<String>()
    private let router: WeakRouter<ChatwootRoute>

    init(
        apiWrapper: APIWrapper,
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        router: WeakRouter<ChatwootRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.router = router

        super.init()
        
        subscribeToChatNotifications()
    }
    
    func transform(_ input: Input) -> Output {
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.premain)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
        )
    }

    private func subscribeToChatNotifications() {
        NotificationCenter.default.rx.notification(.chatRequested)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] notification in
                    guard let self = self,
                        let rawServiceAction = notification.userInfo?[NotificationKeys.serviceActionKey] as? String,
                        let serviceAction = SettingsServiceAction(rawValue: rawServiceAction),
                        let rawServiceType = notification.userInfo?[NotificationKeys.serviceTypeKey] as? String,
                        let serviceType = SettingsServiceType(rawValue: rawServiceType) else {
                        return
                    }

                    let contractName = notification.userInfo?[NotificationKeys.contractNameKey] as? String
                    let request = serviceAction.request(for: serviceType, contractName: contractName)

                    self.automaticMessage.onNext(request)
                }
            )
            .disposed(by: disposeBag)
    }
}

extension ChatwootViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
    }
    
    struct Output {
    }

}
