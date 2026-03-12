//
//  MainTabBarQuickActionOpener.swift
//  SmartYard
//
//  Created by Александр Попов on 05.03.2026.
//

import Foundation
import RxSwift
import XCoordinator

protocol MainTabBarQuickActionOpening {
    func open(_ shortcutType: AppShortcutType)
}

final class MainTabBarQuickActionOpener: MainTabBarQuickActionOpening, HasDisposeBag {
    private let resolver: QuickActionResolverService
    private let homeRouter: StrongRouter<HomeRoute>
    private let menuRouter: StrongRouter<MainMenuRoute>
    private let selectTab: (MainTabBarRoute) -> Void
    private let alertService: AlertService

    init(
        resolver: QuickActionResolverService,
        homeRouter: StrongRouter<HomeRoute>,
        menuRouter: StrongRouter<MainMenuRoute>,
        selectTab: @escaping (MainTabBarRoute) -> Void,
        alertService: AlertService
    ) {
        self.resolver = resolver
        self.homeRouter = homeRouter
        self.menuRouter = menuRouter
        self.selectTab = selectTab
        self.alertService = alertService
    }

    func open(_ shortcutType: AppShortcutType) {
        resolver.resolve(shortcutType)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] resolution in
                    guard let self else { return }

                    switch resolution {
                    case let .target(target):
                        openQuickActionTarget(target)
                    case let .unavailable(message):
                        showQuickActionUnavailableAlert(message: message)
                    }
                },
                onFailure: { [weak self] error in
                    self?.handleQuickActionFailure(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func openQuickActionTarget(_ target: QuickActionResolvedTarget) {
        switch target {
        case let .homeCamerasMap(houseId, address, cameras):
            performOnHomeTab { [weak self] in
                self?.homeRouter.trigger(
                    .yardCamerasMap(
                        houseId: houseId,
                        address: address,
                        cameras: cameras
                    )
                )
            }
        case let .homeCamerasList(houseId, address, tree):
            performOnHomeTab { [weak self] in
                self?.homeRouter.trigger(
                    .yardCamerasList(
                        houseId: houseId,
                        address: address,
                        tree: tree,
                        path: []
                    )
                )
            }
        case let .homeEvents(houseId, address):
            performOnHomeTab { [weak self] in
                self?.homeRouter.trigger(
                    .history(
                        houseId: houseId,
                        address: address
                    )
                )
            }
        case let .menuAddressAccess(address, flatId, clientId):
            performOnMenuTab { [weak self] in
                self?.menuRouter.trigger(
                    .addressAccess(
                        address: address,
                        flatId: flatId,
                        clientId: clientId
                    )
                )
            }
        }
    }
}

private extension MainTabBarQuickActionOpener {
    func performOnHomeTab(_ action: @escaping () -> Void) {
        selectTab(.home)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            action()
        }
    }

    func performOnMenuTab(_ action: @escaping () -> Void) {
        selectTab(.menu)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            action()
        }
    }

    func showQuickActionUnavailableAlert(message: String) {
        alertService.showAlert(
            title: L10n.Common.error,
            message: message,
            priority: 250
        )
    }

    func showQuickActionErrorAlert(error: Error) {
        alertService.showAlert(
            title: L10n.Common.error,
            message: error.localizedDescription,
            priority: 250
        )
    }

    func handleQuickActionFailure(_ error: Error) {
        // Fallback to Home so quick action never leaves user on a blank state.
        selectTab(.home)
        showQuickActionErrorAlert(error: error)
    }
}
