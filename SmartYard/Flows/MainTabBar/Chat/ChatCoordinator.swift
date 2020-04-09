//
//  ChatCoordinator.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

enum ChatRoute: Route {
    case main
}

class ChatCoordinator: NavigationCoordinator<ChatRoute> {
    
    private let disposeBag = DisposeBag()
    private let accessService: AccessService
    
    init(accessService: AccessService) {
        self.accessService = accessService
        
        super.init(initialRoute: .main)
        
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepareTransition(for route: ChatRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = ChatViewModel(accessService: accessService)
            let vc = ChatViewController(viewModel: vm)
            
            // MARK: Загружаю сразу, чтобы иметь возможность нормально отправлять сообщения с "тарелочек"
            // Когда мы жмем на услугу, происходит отправка уведомления в Notification Center
            // Оно перебрасывает нас во вкладку "Чат", а затем vm пытается отправить сообщение
            // Вот только view в этот момент еще может быть не загружена, а transform - не вызван
            // Поэтому проще сразу ее загрузить, чем разруливать сложности
            
            vc.loadViewIfNeeded()
            
            return .set([vc])
        }
    }
    
}
