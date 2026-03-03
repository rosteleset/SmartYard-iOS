//
//  AppCoordinatorDependencies.swift
//  SmartYard
//
//  Created by Александр Попов on 03.03.2026.
//

import Foundation

protocol AppDependencies {
    var linphoneService: LinphoneService { get }
    var providerProxy: CXProviderProxy { get }

    var accessService: AccessService { get }
    var permissionService: PermissionService { get }

    var apiWrapper: APIWrapper { get }
    var issueService: IssueService { get }
    var pushNotificationService: PushNotificationService { get }
    var alertService: AlertService { get }
    var telemetryService: AppTelemetryServicing { get }
    var logoutHelper: LogoutHelper { get }

    var debugNetwork: DebugNetworkController { get }
    var networkEnv: NetworkEnvironment { get }
    var networkStateProvider: NetworkStateProviding { get }
    var offlineAddressListDataSource: OfflineAddressListDataSource { get }
    var optionsService: OptionsServicing { get }
}

final class DefaultAppDependencies: AppDependencies {
    let linphoneService: LinphoneService
    let providerProxy: CXProviderProxy

    let accessService: AccessService
    let permissionService: PermissionService

    let apiWrapper: APIWrapper
    let issueService: IssueService
    let pushNotificationService: PushNotificationService
    let alertService: AlertService
    let telemetryService: AppTelemetryServicing
    let logoutHelper: LogoutHelper

    let debugNetwork: DebugNetworkController
    let networkEnv: NetworkEnvironment
    let networkStateProvider: NetworkStateProviding
    let offlineAddressListDataSource: OfflineAddressListDataSource
    let optionsService: OptionsServicing

    init(
        accessService: AccessService = .shared,
        permissionService: PermissionService = PermissionService(),
        alertService: AlertService = AlertService(),
        telemetryService: AppTelemetryServicing = AppTelemetryService.shared,
        debugNetwork: DebugNetworkController = DebugNetworkController(),
        linphoneService: LinphoneService = LinphoneService(),
        providerProxy: CXProviderProxy = CXProviderProxy()
    ) {
        self.accessService = accessService
        self.permissionService = permissionService
        self.alertService = alertService
        self.telemetryService = telemetryService
        self.debugNetwork = debugNetwork
        self.linphoneService = linphoneService
        self.providerProxy = providerProxy

        self.networkEnv = NetworkEnvironment.make(debug: debugNetwork)
        self.apiWrapper = APIWrapper(
            accessService: accessService,
            session: networkEnv.session,
            internet: networkEnv.internet,
            backend: networkEnv.backend
        )
        self.issueService = IssueService(
            apiWrapper: apiWrapper,
            accessService: accessService
        )
        self.pushNotificationService = PushNotificationService(apiWrapper: apiWrapper)
        self.logoutHelper = LogoutHelper(
            pushNotificationService: pushNotificationService,
            accessService: accessService,
            alertService: alertService
        )
        self.networkStateProvider = NetworkStateProvider(
            internet: networkEnv.internet,
            backend: networkEnv.backend
        )
        self.offlineAddressListDataSource = OfflineAddressListDataSource(
            container: PersistenceController.shared.container
        )
        self.optionsService = OptionsService(
            apiWrapper: apiWrapper,
            accessService: accessService,
            networkStateProvider: networkStateProvider
        )
    }
}
