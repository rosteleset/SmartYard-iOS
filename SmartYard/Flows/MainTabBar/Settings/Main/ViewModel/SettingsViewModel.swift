//
//  SettingsViewModel.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class SettingsViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    private let apiWrapper: APIWrapper
    
    // MARK: Словарь необходим для того, чтобы хранить состояния раскрытости секций
    private let areSectionsExpanded = BehaviorSubject<[String: Bool]>(value: [:])
    
    // MARK: Загруженные данные (пока моковые модели)
    private let loadedData = BehaviorSubject<[APISettingsAddress]>(value: [])
    
    init(router: WeakRouter<SettingsRoute>, apiWrapper: APIWrapper) {
        self.router = router
        self.apiWrapper = apiWrapper
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        input.viewDidLoadTrigger
            .flatMapLatest { [weak self] _ -> Driver<GetSettingsListResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.getSettingsAddresses()
//                    .trackActivity()
//                    .trackError()
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] result in
                    self?.loadedData.onNext(result)
                }
            )
            .disposed(by: self.disposeBag)
        
        // MARK: Обработка нажатия на иконку настроек
        input.advancedSettingsTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.advancedSettings(name: "Алексеев В.Б."))
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на кнопку сервиса
        
        input.serviceSelected
            .withLatestFrom(loadedData.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (serviceSelected, loadedData) = args
                    let (identity, serviceType) = serviceSelected
                    
                    guard case let .controlPanel(clientId) = identity,
                        let match = (loadedData.first { $0.clientId == clientId }),
                        let isActivated = match.servicesAvailability[serviceType] else {
                        return
                    }
                    
                    if isActivated {
                        self?.router.trigger(.serviceIsActivated)
                    } else {
                        // TODO
                    }
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на настройки адреса
        
        input.itemSelected
            .flatMap { identity -> Driver<String> in
                guard case let .action(clientId, type) = identity, type == .openAddressSettings else {
                    return .empty()
                }
                
                return .just(clientId)
            }
            .withLatestFrom(loadedData.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (clientId, loadedData) = args
                    
                    guard let match = (loadedData.first { $0.clientId == clientId }) else {
                        return
                    }
                    
                    self?.router.trigger(.addressSettings(address: match.address))
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на предоставление доступа
        
        input.itemSelected
            .flatMap { identity -> Driver<String> in
                guard case let .action(clientId, type) = identity, type == .grantAccess else {
                    return .empty()
                }
                
                return .just(clientId)
            }
            .withLatestFrom(loadedData.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (clientId, loadedData) = args
                    
                    guard let match = (loadedData.first { $0.clientId == clientId }) else {
                        return
                    }
                    
                    self?.router.trigger(.addressAccess(address: match.address))
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: При скрытии / раскрытии секций передаем информацию о секции, чтобы View могла выполнить скроллинг
        
        let updateKindSubject = PublishSubject<SettingsSectionUpdateKind>()
        let updateKind = updateKindSubject.asDriverOnErrorJustComplete()
        
        // MARK: При нажатии на Header, обновляем состояние раскрытости для этой секции
        // Это приведет к обновлению секций
        
        input.itemSelected
            .flatMap { identity -> Driver<String> in
                guard case let .header(addressId) = identity else {
                    return .empty()
                }
                
                return .just(addressId)
            }
            .withLatestFrom(areSectionsExpanded.asDriverOnErrorJustComplete()) { ($0, $1) }
            .map { args -> ((String, Bool), [String: Bool]) in
                var (clientId, dict) = args
                
                let newState = !dict[clientId, default: false]
                dict[clientId] = newState
                
                return ((clientId, newState), dict)
            }
            
            // MARK: Вынес в блок do, чтобы не делать сайд-эффектов в map
            
            .do(
                onNext: { args in
                    let (updatedSectionInfo, _) = args
                    let (clientId, newState) = updatedSectionInfo
                    
                    let identity = SettingsDataItemIdentity.header(clientId: clientId)
                    
                    updateKindSubject.onNext(
                        newState ?
                            .expand(sectionWithIdentity: identity) :
                            .collapse(sectionWithIdentity: identity)
                    )
                }
            )
            .map { args in
                let (_, dict) = args
                return dict
            }
            .drive(
                onNext: { [weak self] newDict in
                    self?.areSectionsExpanded.onNext(newDict)
                }
            )
            .disposed(by: disposeBag)
        
        let sectionModels: Driver<[SettingsSectionModel]> = Driver
            .combineLatest(
                loadedData.asDriver(onErrorJustReturn: []),
                areSectionsExpanded.asDriver(onErrorJustReturn: [:])
            )
            .map { [weak self] args in
                let (data, expansionStateDict) = args
                
                return self?.createMockSections(data: data, expansionStateDict: expansionStateDict) ?? []
            }
        
        return Output(
            sectionModels: sectionModels,
            updateKind: updateKind
        )
    }
    
    private func createMockSections(
        data: [APISettingsAddress],
        expansionStateDict: [String: Bool]
    ) -> [SettingsSectionModel] {
        // swiftlint:disable:next closure_body_length
        let mainSections: [SettingsSectionModel] = data.map { example in
            let isExpanded = expansionStateDict[example.clientId!, default: false]
            
            let header: SettingsDataItem = .header(
                identity: .header(clientId: example.clientId!),
                address: example.address,
                contract: example.contractName!,
                isExpanded: isExpanded
            )
            
            let objects: [SettingsDataItem] = {
                guard isExpanded else {
                    return []
                }
                
                let controlPanel: SettingsDataItem = .controlPanel(
                    identity: .controlPanel(clientId: example.clientId!),
                    serviceStates: example.servicesAvailability
                )
                
                let openAddressSettingsAction: SettingsDataItem = .action(
                    identity: .action(
                        clientId: example.clientId!,
                        type: .openAddressSettings
                    )
                )
                
                let grantAccessAction: SettingsDataItem = .action(
                    identity: .action(
                        clientId: example.clientId!,
                        type: .grantAccess
                    )
                )
                
                let webVersionAction: SettingsDataItem = .action(
                    identity: .action(
                        clientId: example.clientId!,
                        type: .openWebVersion
                    )
                )
                
                return [controlPanel, openAddressSettingsAction, grantAccessAction, webVersionAction]
            }()
            
            return SettingsSectionModel(identity: example.clientId!, items: [header] + objects)
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
        let viewDidLoadTrigger: Driver<Bool>
        let itemSelected: Driver<SettingsDataItemIdentity>
        let serviceSelected: Driver<(SettingsDataItemIdentity, SettingsServiceType)>
        let advancedSettingsTrigger: Driver<Void>
    }
    
    struct Output {
        let sectionModels: Driver<[SettingsSectionModel]>
        let updateKind: Driver<SettingsSectionUpdateKind>
    }
    
}
