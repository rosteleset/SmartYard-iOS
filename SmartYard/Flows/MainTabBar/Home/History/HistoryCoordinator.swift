//
//  HistoryCoordinator.swift
//  SmartYard
//
//  Created by Александр Васильев on 04.09.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import XCoordinator
import RxSwift
import RxCocoa

enum HistoryRoute: Route {
    case alert(title: String, message: String?)
    case dialog(title: String, message: String?, actions: [UIAlertAction])
    case back
    case dismiss
    case main(houseId: Int? = nil, flatId: Int? = nil, eventsFilter: EventsFilter = .all, address: String)
    case detail(viewModel: HistoryViewModel, item: HistoryDataItem)
    case addFaceFromEvent(event: APIPlog)
    case deleteFaceFromEvent(event: APIPlog, imageURL: String?)
    case showModal(withContent: ModalContent)
}

class HistoryCoordinator: NavigationCoordinator<HistoryRoute> {
    
    private let disposeBag = DisposeBag()
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let issueService: IssueService
    private let permissionService: PermissionService
    private let alertService: AlertService
    private let logoutHelper: LogoutHelper
    
    init(
        rootVC: UINavigationController,
        apiWrapper: APIWrapper,
        pushNotificationService: PushNotificationService,
        accessService: AccessService,
        issueService: IssueService,
        permissionService: PermissionService,
        alertService: AlertService,
        logoutHelper: LogoutHelper,
        houseId: Int? = nil,
        flatId: Int? = nil,
        eventsFilter: EventsFilter = .all,
        address: String
    ) {
        self.apiWrapper = apiWrapper
        self.pushNotificationService = pushNotificationService
        self.accessService = accessService
        self.issueService = issueService
        self.permissionService = permissionService
        self.alertService = alertService
        self.logoutHelper = logoutHelper
        
        super.init(rootViewController: rootVC, initialRoute: nil)
        trigger(.main(houseId: houseId, flatId: flatId, eventsFilter: eventsFilter, address: address))
        
        rootViewController.setNavigationBarHidden(true, animated: false)
        
    }
    
    override func prepareTransition(for route: HistoryRoute) -> NavigationTransition {
        switch route {
        case let .alert(title, message):
            return .alertTransition(title: title, message: message)
            
        case let .dialog(title, message, actions):
            return .dialogTransition(title: title, message: message, actions: actions)
            
        case .back:
            return .pop(animation: .default)
            
        case .dismiss:
            return .dismiss()
            
        case let .main(houseId, flatId, eventsFilter, address):
            let vm = HistoryViewModel(
                apiWrapper: apiWrapper,
                houseId: houseId,
                flatId: flatId,
                eventsFilter: eventsFilter,
                address: address,
                router: weakRouter
            )
            let vc = HistoryViewController(viewModel: vm)
            
            return .push(vc)
            
        case let .detail(vm, item):
            let vc = HistoryDetailViewController(viewModel: vm, focusedOn: item)
   
            return .push(vc)
            
        case let .addFaceFromEvent(event):
            let vc = AddFaceViewController(apiWrapper: apiWrapper, event: event)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
       
        case let .deleteFaceFromEvent(event, imageURL):
            let vc = DeleteFaceViewController(apiWrapper: apiWrapper, imageURL: imageURL, event: event)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
            
        case let .showModal(content):
            let vc = ModalViewController(dismissCallback: { self.trigger(.dismiss) }, content: content)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            return .present(vc)
        }
    }
}

