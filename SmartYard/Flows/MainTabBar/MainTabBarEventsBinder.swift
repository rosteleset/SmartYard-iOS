//
//  MainTabBarEventsBinder.swift
//  SmartYard
//
//  Created by Александр Попов on 05.03.2026.
//

import Foundation
import RxSwift
import RxCocoa

protocol MainTabBarEventsBinding {
    var notificationsBadgeChanged: Driver<Bool> { get }
    var chatBadgeChanged: Driver<Bool> { get }
    var addAddressRequested: Signal<Void> { get }
    var chatRequested: Signal<Void> { get }
    var optionsUpdated: Driver<Void> { get }
}

final class MainTabBarEventsBinder: MainTabBarEventsBinding {
    private let optionsService: OptionsServicing
    private let notificationCenter: NotificationCenter

    private(set) lazy var notificationsBadgeChanged: Driver<Bool> = {
        Driver.merge(
            notificationCenter.rx.notification(.unreadInboxMessagesAvailable)
                .asDriverOnErrorJustComplete()
                .mapToTrue(),
            notificationCenter.rx.notification(.allInboxMessagesRead)
                .asDriverOnErrorJustComplete()
                .mapToFalse()
        )
    }()

    private(set) lazy var chatBadgeChanged: Driver<Bool> = {
        Driver.merge(
            notificationCenter.rx.notification(.unreadChatMessagesAvailable)
                .asDriverOnErrorJustComplete()
                .mapToTrue(),
            notificationCenter.rx.notification(.allChatMessagesRead)
                .asDriverOnErrorJustComplete()
                .mapToFalse()
        )
    }()

    private(set) lazy var addAddressRequested: Signal<Void> = {
        notificationCenter.rx.notification(Notification.Name.addAddressFromSettings)
            .asSignalOnErrorJustComplete()
            .mapToVoid()
    }()

    private(set) lazy var chatRequested: Signal<Void> = {
        notificationCenter.rx.notification(Notification.Name.chatRequested)
            .asSignalOnErrorJustComplete()
            .mapToVoid()
    }()

    private(set) lazy var optionsUpdated: Driver<Void> = {
        optionsService.optionsUpdated
            .asDriverOnErrorJustComplete()
    }()

    init(
        optionsService: OptionsServicing,
        notificationCenter: NotificationCenter = .default
    ) {
        self.optionsService = optionsService
        self.notificationCenter = notificationCenter
    }
}
