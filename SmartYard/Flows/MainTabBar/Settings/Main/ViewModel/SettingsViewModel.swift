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
    private let loadedData = BehaviorSubject<[APISettingsAddress]>(value: [])
    
    init(router: WeakRouter<SettingsRoute>, apiWrapper: APIWrapper) {
        self.router = router
        self.apiWrapper = apiWrapper
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        let errorTracker = ErrorTracker()
        
        let isInitialLoadingFinishedSubject = BehaviorSubject<Bool>(value: false)
        let isInitialLoadingFinished = isInitialLoadingFinishedSubject.asDriver(onErrorJustReturn: false)
        
        let reloadingFinishedSubject = PublishSubject<Void>()
        let reloadingFinished = reloadingFinishedSubject.asDriverOnErrorJustComplete()
        
        Driver<Void>
            .merge(
                input.updateDataTrigger.asDriver().delay(.milliseconds(1000)),
                .just(())
            )
            .flatMapLatest { [weak self] _ -> Driver<GetSettingsListResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.getSettingsAddresses()
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .do(
                onNext: { _ in
                    isInitialLoadingFinishedSubject.onNext(true)
                    reloadingFinishedSubject.onNext(())
                }
            )
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
        
        let serviceActivatedTrigger = PublishSubject<String?>()
        let serviceUnactivatedTrigger = PublishSubject<(SettingsServiceType, String?)?>()
        
        input.serviceSelected
            .withLatestFrom(loadedData.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (serviceSelected, loadedData) = args
                    let (identity, serviceType) = serviceSelected
                    
                    guard case let .controlPanel(uniqueId) = identity,
                        let match = (loadedData.first { $0.uniqueId == uniqueId }),
                        let isActivated = match.servicesAvailability[serviceType] else {
                        return
                    }
                    
                    guard isActivated else {
                        serviceUnactivatedTrigger.onNext((serviceType, match.houseId))
                        return
                    }
                    
                    serviceActivatedTrigger.onNext(match.clientId)
                }
            )
            .disposed(by: disposeBag)
        
        serviceActivatedTrigger
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] clientId in
                    self?.router.trigger(.serviceIsActivated(clientId: clientId))
                }
            )
            .disposed(by: disposeBag)
        
        serviceUnactivatedTrigger
            .asDriver(onErrorJustReturn: nil)
            .flatMap { [weak self] args -> GetServicesResponseData? in
                guard let self = self,
                      let (type, houseId) = args
                else {
                    return (nil, .empty())
                }
                
                return self.apiWrapper.getServicesByHouseId(houseId: houseId)
            }

        // MARK: Обработка нажатия на настройки адреса
        
        input.itemSelected
            .flatMap { identity -> Driver<String> in
                guard case let .action(uniqueId, type) = identity, type == .openAddressSettings else {
                    return .empty()
                }
                
                return .just(uniqueId)
            }
            .withLatestFrom(loadedData.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (uniqueId, loadedData) = args
                    
                    guard let match = (loadedData.first { $0.uniqueId == uniqueId }) else {
                        return
                    }
                    
                    self?.router.trigger(.addressSettings(address: match.address))
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Обработка нажатия на предоставление доступа
        
        input.itemSelected
            .flatMap { identity -> Driver<String> in
                guard case let .action(uniqueId, type) = identity, type == .grantAccess else {
                    return .empty()
                }
                
                return .just(uniqueId)
            }
            .withLatestFrom(loadedData.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (uniqueId, loadedData) = args
                    
                    guard let match = (loadedData.first { $0.uniqueId == uniqueId }),
                          let flatId = match.flatId
                    else {
                        return
                    }
                    
                    self?.router.trigger(
                        .addressAccess(
                            address: match.address,
                            flatId: flatId
                        )
                    )
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
                guard case let .header(uniqueId) = identity else {
                    return .empty()
                }
                
                return .just(uniqueId)
            }
            .withLatestFrom(areSectionsExpanded.asDriverOnErrorJustComplete()) { ($0, $1) }
            .map { args -> ((String, Bool), [String: Bool]) in
                var (uniqueId, dict) = args
                
                let newState = !dict[uniqueId, default: false]
                dict[uniqueId] = newState
                
                return ((uniqueId, newState), dict)
            }
            
            // MARK: Вынес в блок do, чтобы не делать сайд-эффектов в map
            
            .do(
                onNext: { args in
                    let (updatedSectionInfo, _) = args
                    let (uniqueId, newState) = updatedSectionInfo
                    
                    let identity = SettingsDataItemIdentity.header(uniqueId: uniqueId)
                    
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
                
                return self?.createSections(data: data, expansionStateDict: expansionStateDict) ?? []
            }
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            sectionModels: sectionModels,
            updateKind: updateKind,
            isInitialLoadingFinished: isInitialLoadingFinished,
            reloadingFinished: reloadingFinished
        )
    }
    
    private func createSections(
        data: [APISettingsAddress],
        expansionStateDict: [String: Bool]
    ) -> [SettingsSectionModel] {
        // swiftlint:disable:next closure_body_length
        let mainSections: [SettingsSectionModel] = data.map { item in
            let isExpanded = expansionStateDict[item.uniqueId, default: false]
            
            let contractName: String? = {
                guard let contractName = item.contractName else {
                    return nil
                }
                
                return "Номер договора: \(contractName)"
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
                
                let controlPanel: SettingsDataItem = .controlPanel(
                    identity: .controlPanel(uniqueId: item.uniqueId),
                    serviceStates: item.servicesAvailability
                )
                
                let openAddressSettingsAction: SettingsDataItem = .action(
                    identity: .action(
                        uniqueId: item.uniqueId,
                        type: .openAddressSettings
                    )
                )
                
                let grantAccessAction: SettingsDataItem = .action(
                    identity: .action(
                        uniqueId: item.uniqueId,
                        type: .grantAccess
                    )
                )
                
                let webVersionAction: SettingsDataItem = .action(
                    identity: .action(
                        uniqueId: item.uniqueId,
                        type: .openWebVersion
                    )
                )
                
                return [controlPanel, openAddressSettingsAction, grantAccessAction, webVersionAction]
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
        let itemSelected: Driver<SettingsDataItemIdentity>
        let serviceSelected: Driver<(SettingsDataItemIdentity, SettingsServiceType)>
        let advancedSettingsTrigger: Driver<Void>
        let updateDataTrigger: Driver<Void>
    }
    
    struct Output {
        let sectionModels: Driver<[SettingsSectionModel]>
        let updateKind: Driver<SettingsSectionUpdateKind>
        let isInitialLoadingFinished: Driver<Bool>
        let reloadingFinished: Driver<Void>
    }
    
}
