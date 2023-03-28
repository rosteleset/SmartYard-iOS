//
//  ChatViewModel.swift
//  SmartYard
//
//  Created by admin on 31/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa
import WebKit


class ChatWootViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    
    private let automaticMessage = PublishSubject<String>()
    
    init(
        apiWrapper: APIWrapper,
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        logoutHelper: LogoutHelper,
        alertService: AlertService
    ) {
        self.apiWrapper = apiWrapper
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        
        super.init()
                       
    }
    

    
}

extension ChatViewModel {
    
    struct Input {
        let viewWillAppearTrigger: Driver<Bool>
        let isViewVisible: Driver<Bool>
    }
    
    struct Output {
        let phone: Driver<String?>
        let name: Driver<String?>
        let chatConfiguration: Driver<ChatConfiguration>
        let automaticMessage: Driver<String>
        let isLoggingOut: Driver<Bool>
    }
    
}
