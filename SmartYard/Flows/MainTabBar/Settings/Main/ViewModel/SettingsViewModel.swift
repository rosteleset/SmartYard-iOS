//
//  SettingsViewModel.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

// Нужно чтобы 1 адрес у ячейки был открытым в начальном состоянии

import RxSwift
import RxCocoa
import XCoordinator

final class SettingsViewModel: BaseViewModel {
    
    let router: WeakRouter<SettingsRoute>
    let apiWrapper: APIWrapper
    let accessService: AccessService
    let logoutHelper: LogoutHelper
    private let alertService: AlertService
    let networkStateProvider: NetworkStateProviding

    // MARK: Словарь необходим для того, чтобы хранить состояния раскрытости секций
    let areSectionsExpanded = BehaviorSubject<[String: Bool]>(value: [:])
    let loadedData = BehaviorSubject<[APISettingsAddress]>(value: [])
    
    init(
        router: WeakRouter<SettingsRoute>,
        apiWrapper: APIWrapper,
        accessService: AccessService,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        networkStateProvider: NetworkStateProviding
    ) {
        self.router = router
        self.apiWrapper = apiWrapper
        self.accessService = accessService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.networkStateProvider = networkStateProvider
    }
    
    // swiftlint:disable:next function_body_length
    func createSections(
        data: [APISettingsAddress],
        expansionStateDict: [String: Bool],
        isEventsTrackingEnabled: Bool
    ) -> [SettingsSectionModel] {
        // swiftlint:disable:next closure_body_length
        let mainSections: [SettingsSectionModel] = data.map { item in
            let isExpanded = expansionStateDict[item.uniqueId, default: false]
            
            let contractName: String? = {
                guard let contractName = item.contractName else {
                    return nil
                }
                
                return L10n.Settings.Main.contractNumberTitle + ": \(contractName)"
            }()
            
            let header: SettingsDataItem = .header(
                identity: .header(uniqueId: item.uniqueId),
                address: item.address,
                contractName: contractName,
                isExpanded: isExpanded
            )
            
            let objects: [SettingsDataItem] = {
                guard isExpanded else {
                    return []
                }
                
                let controlPanel: SettingsDataItem? = {
                    let serviceStates = item.controlPanelServiceStates
                    guard (item.contractOwner ?? false) || (item.flatOwner ?? false),
                          !serviceStates.isEmpty else {
                        return nil
                    }
                    
                    return .controlPanel(
                        identity: .controlPanel(uniqueId: item.uniqueId),
                        serviceStates: serviceStates
                    )
                }()
                
                let openAddressSettingsAction: SettingsDataItem? = {
                    guard item.flatId != nil else {
                        return nil
                    }
                    
                    return .action(
                        identity: .action(
                            uniqueId: item.uniqueId,
                            type: .openAddressSettings
                        )
                    )
                }()

                let trackedEventsAction: SettingsDataItem? = {
                    guard isEventsTrackingEnabled,
                          let rawFlatId = item.flatId,
                          Int(rawFlatId) != nil else {
                        return nil
                    }

                    return .action(
                        identity: .action(
                            uniqueId: item.uniqueId,
                            type: .trackedEvents
                        )
                    )
                }()
                
                let grantAccessAction: SettingsDataItem? = {
                    guard item.flatId != nil, item.servicesAvailability[.domophone] == true else {
                        return nil
                    }
                    
                    return .action(
                        identity: .action(
                            uniqueId: item.uniqueId,
                            type: .grantAccess
                        )
                    )
                }()
                
                let webVersionAction: SettingsDataItem? = {
                    guard let lcab = item.lcab, URL(string: lcab) != nil else {
                        return nil
                    }
                    
                    return .action(
                        identity: .action(
                            uniqueId: item.uniqueId,
                            type: .openWebVersion
                        )
                    )
                }()
                
                return [
                    controlPanel,
                    openAddressSettingsAction,
                    trackedEventsAction,
                    grantAccessAction,
                    webVersionAction
                ]
                    .compactMap { $0 }
            }()
            
            return SettingsSectionModel(identity: item.uniqueId, items: [header] + objects)
        }
        
        let addAddressSection = SettingsSectionModel(
            identity: "AddAddressSection",
            items: [SettingsDataItem.addAddress]
        )
        
        return mainSections + [addAddressSection]
    }
    
}

extension SettingsViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let itemSelected: Driver<SettingsDataItemIdentity>
        let serviceSelected: Driver<(SettingsDataItemIdentity, SettingsServiceType)>
        let updateDataTrigger: Driver<Void>
        let addAddressTrigger: Driver<Void>
    }
    
    struct Output {
        let sectionModels: Driver<[SettingsSectionModel]>
        let updateKind: Driver<SettingsSectionUpdateKind>
        let reloadingFinished: Driver<Void>
        let shouldBlockInteraction: Driver<Bool>
        let isLoading: Driver<Bool>
    }
    
    struct ServiceUnactivatedResponsePayload {
        let serviceType: SettingsServiceType
        let apiSettingsAddress: APISettingsAddress
        let availableServices: GetServicesResponseData
    }
    
}
