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

enum MainMenuRoute: Route {
    
    case main
    case cityCams
    case settings
    case addressAccess(address: String, flatId: String, clientId: String?)
    case profile
    case callSupport
    case alert(title: String, message: String)
    case back
    case webView(url: URL, version: Int)
    case webViewFromContent(content: String, baseURL: String, version: Int)
}

class MainMenuCoordinator: NavigationCoordinator<MainMenuRoute>, HasDisposeBag {


    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    private let permissionService: PermissionService
    private let alertService: AlertService
    private let logoutHelper: LogoutHelper
    private let networkStateProvider: NetworkStateProviding
    private let supportCallActionsPresenter: SupportCallActionsPresenting
    private let requestSupportCallbackUseCase: RequestSupportCallbackUseCase
    private let phoneDialer: PhoneDialing

    private var settingsRouter: StrongRouter<SettingsRoute>!
    private var cityCamsRouter: StrongRouter<CityCamsRoute>!

    init(
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        apiWrapper: APIWrapper,
        issueService: IssueService,
        permissionService: PermissionService,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        networkStateProvider: NetworkStateProviding,
        supportCallActionsPresenter: SupportCallActionsPresenting,
        requestSupportCallbackUseCase: RequestSupportCallbackUseCase,
        phoneDialer: PhoneDialing
    ) {
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.permissionService = permissionService
        self.alertService = alertService
        self.logoutHelper = logoutHelper
        self.networkStateProvider = networkStateProvider
        self.supportCallActionsPresenter = supportCallActionsPresenter
        self.requestSupportCallbackUseCase = requestSupportCallbackUseCase
        self.phoneDialer = phoneDialer

        super.init(initialRoute: .main)

        let settingsCoordinator = SettingsCoordinator(
            rootViewController: rootViewController,
            accessService: accessService,
            pushNotificationService: pushNotificationService,
            apiWrapper: apiWrapper,
            issueService: issueService,
            permissionService: permissionService,
            logoutHelper: logoutHelper,
            alertService: alertService,
            networkStateProvider: networkStateProvider
        )

        let cityCamsCoordinator = CityCamsCoordinator(
            rootViewController: rootViewController,
            apiWrapper: apiWrapper,
            pushNotificationService: pushNotificationService,
            accessService: accessService,
            issueService: issueService,
            permissionService: permissionService,
            alertService: alertService,
            logoutHelper: logoutHelper
        )

        self.settingsRouter = settingsCoordinator.strongRouter
        self.cityCamsRouter = cityCamsCoordinator.strongRouter

        rootViewController.setNavigationBarHidden(true, animated: false)
    }

    // swiftlint:disable:next function_body_length
    override func prepareTransition(for route: MainMenuRoute) -> NavigationTransition {
        switch route {
        case .main:
            let vm = MainMenuViewModel(
                apiWrapper: apiWrapper,
                accessService: accessService,
                router: weakRouter,
                networkStateProvider: networkStateProvider
            )
            let vc = MainMenuViewController(viewModel: vm)
            return .set([vc])

        case .cityCams:
            return .trigger(CityCamsRoute.main, on: cityCamsRouter)

        case .settings:
            return .trigger(SettingsRoute.main, on: settingsRouter)

        case let .addressAccess(address, flatId, clientId):
            return .trigger(
                SettingsRoute.addressAccess(
                    address: address,
                    flatId: flatId,
                    clientId: clientId
                ),
                on: settingsRouter
            )

        case .profile:
            return .trigger(SettingsRoute.advancedSettings, on: settingsRouter)

        case .callSupport:
            openSupportActions()
            return .none()

        case let .alert(title, message):
            return .alertTransition(title: title, message: message)

        case .back:
            return .pop(animation: .default)

        case let .webView(url, version):
            let coordinator = WebViewCoordinator(
                rootVC: rootViewController,
                apiWrapper: apiWrapper,
                networkStateProvider: networkStateProvider,
                url: url,
                backButtonLabel: NSLocalizedString("Menu", comment: ""),
                push: true,
                version: version
            )

            addChild(coordinator)
            return .none()

        case let .webViewFromContent(content, baseURL, version):
            let coordinator = WebViewCoordinator(
                rootVC: rootViewController,
                apiWrapper: apiWrapper,
                networkStateProvider: networkStateProvider,
                content: content,
                baseURL: baseURL,
                backButtonLabel: NSLocalizedString("Menu", comment: ""),
                push: true,
                version: version
            )

            addChild(coordinator)
            return .none()
        }
    }
}

private extension MainMenuCoordinator {
    func openSupportActions() {
        supportCallActionsPresenter.present(
            from: viewController
        ) { [weak self] action in
            guard let self else { return }

            switch action {
            case .requestCallback:
                requestSupportCallback()
            case .phoneCall:
                phoneDialer.call(accessService.supportPhone)
            }
        }
    }

    func requestSupportCallback() {
        requestSupportCallbackUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] in
                    self?.trigger(
                        .alert(
                            title: NSLocalizedString("Request submitted", comment: ""),
                            message: NSLocalizedString("We will call you shortly", comment: "")
                        )
                    )
                },
                onFailure: { [weak self] error in
                    self?.trigger(
                        .alert(
                            title: NSLocalizedString("Error", comment: ""),
                            message: error.localizedDescription
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
    }
}
