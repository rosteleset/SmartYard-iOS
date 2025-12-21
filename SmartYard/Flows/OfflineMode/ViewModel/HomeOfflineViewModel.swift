//
//  AddressesListOfflineViewModel.swift
//  SmartYard
//
//  Created by Александр Попов on 19.10.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxSwift
import RxRelay
import RxCocoa
import XCoordinator

final class HomeOfflineViewModel: BaseViewModel {

    // MARK: - Input / Output

    struct Input {
        let viewDidLoad: Observable<Void>
        let itemSelected: Observable<AddressesListDataItemIdentity>
        let didAttemptToDismiss: Observable<Void>
    }

    struct Output {
        let sectionModels: Driver<[AddressesListSectionModel]>
        let itemsCountBySection: Driver<[Int: Int]>
        let shouldBlockInteraction: Driver<Bool>
        let allowDismiss: Driver<Void>
        let updateKind: Driver<AddressesListSectionUpdateKind>
    }

    // MARK: - Dependencies

    private let accessService: AccessService
    private let offlineAddressListDataSource: OfflineAddressListDataSource
    private let networkStateProvider: NetworkStateProviding
    private let router: WeakRouter<AppRoute>

    // MARK: - State

    private let offlineAddresses = BehaviorRelay<[OfflineAddress]>(value: [])
    private let areSectionsExpanded = BehaviorRelay<[String: Bool]>(value: [:])

    init(
        accessService: AccessService,
        offlineAddressListDataSource: OfflineAddressListDataSource,
        networkStateProvider: NetworkStateProviding,
        router: WeakRouter<AppRoute>
    ) {
        self.accessService = accessService
        self.offlineAddressListDataSource = offlineAddressListDataSource
        self.networkStateProvider = networkStateProvider
        self.router = router
        super.init()
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func transform(_ input: Input) -> Output {
        let requestTracker = ActivityTracker()

        input.viewDidLoad
            .subscribe { [weak self] _ in
                self?.loadOfflineAddresses()
            }
            .disposed(by: disposeBag)

//        input.itemSelected
//            .compactMap { identity -> String? in
//                guard case let .header(addressId) = identity else { return nil }
//                return addressId
//            }
//            .withLatestFrom(areSectionsExpanded.asObservable()) { ($0, $1) }
//            .map { addressId, dict -> [String: Bool] in
//                var dict = dict
//                dict[addressId] = !(dict[addressId] ?? false)
//                return dict
//            }
//            .bind(to: areSectionsExpanded)
//            .disposed(by: disposeBag)

        let allowDismiss = input.didAttemptToDismiss
            .filter { [networkStateProvider] in
                networkStateProvider.currentState == .online
            }
            .do(onNext: { [router] in
                router.trigger(.dismissOffline)
            })
            .mapToVoid()
            .asDriverOnErrorJustComplete()

        input.didAttemptToDismiss
            .filter { [networkStateProvider] in
                return networkStateProvider.currentState != .online
            }
            .mapToVoid()
            .asDriverOnErrorJustComplete()
            .drive { [router] _ in
                router.trigger(
                    .dialog(
                        title: NSLocalizedString("offline.alert.no_connection_title", comment: ""),
                        message: NSLocalizedString("offline.message.server_unavailable", comment: ""),
                        actions: [UIAlertAction(title: "Ок", style: .default)]
                    )
                )
            }
            .disposed(by: disposeBag)

        // MARK: При скрытии / раскрытии секций передаем информацию о секции, чтобы View могла выполнить скроллинг

        let updateKindSubject = PublishSubject<AddressesListSectionUpdateKind>()
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
                var (addressId, dict) = args

                let newState = !dict[addressId, default: false]
                dict[addressId] = newState

                return ((addressId, newState), dict)
            }

        // MARK: Вынес в блок do, чтобы не делать сайд-эффектов в map

            .do(
                onNext: { args in
                    let (updatedSectionInfo, _) = args
                    let (addressId, newState) = updatedSectionInfo

                    let identity = AddressesListDataItemIdentity.header(addressId: addressId)

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
            .subscribe { [weak self] newDict in
                self?.areSectionsExpanded.accept(newDict)
            }
            .disposed(by: disposeBag)

        let sectionModels = Observable
            .combineLatest(
                offlineAddresses.asObservable(),
                areSectionsExpanded.asObservable()
            )
            .map { [weak self] addresses, expansion -> [AddressesListSectionModel] in
                guard let self else { return [] }
                return createSections(addresses: addresses, expansionStateDict: expansion)
            }
            .asDriver(onErrorJustReturn: [])

        let itemsCountBySection = sectionModels
            .map { sections -> [Int: Int] in
                let itemsCountDict: [Int: Int] = sections.enumerated().reduce([:]) { dict, enumeration in
                    let (offset, element) = enumeration

                    var mutableDict = dict
                    mutableDict[offset] = element.items.count
                    return mutableDict
                }

                return itemsCountDict
//                let pairs = sections.enumerated().map {
//                    ($0.offset, $0.element.items.count)
//                }
//                return Dictionary(uniqueKeysWithValues: pairs)
            }

        let shouldBlockInteraction = requestTracker.asDriver()

        return Output(
            sectionModels: sectionModels,
            itemsCountBySection: itemsCountBySection,
            shouldBlockInteraction: shouldBlockInteraction,
            allowDismiss: allowDismiss,
            updateKind: updateKind
        )
    }

    // MARK: - Private

    private func loadOfflineAddresses() {
        do {
            let addresses = try offlineAddressListDataSource.fetchOfflineAddresses()
            offlineAddresses.accept(addresses)

            var dict: [String: Bool] = [:]
            addresses.enumerated().forEach { idx, addr in
                dict[addr.houseId] = (idx == 0)
            }
            areSectionsExpanded.accept(dict)
        } catch {
            offlineAddresses.accept([])
            areSectionsExpanded.accept([:])
        }
    }

    // swiftlint:disable:next function_body_length
    private func createSections(
        addresses: [OfflineAddress],
        expansionStateDict: [String: Bool]
    ) -> [AddressesListSectionModel] {

        var sectionModels = addresses.map { address -> AddressesListSectionModel in
            let addressId = address.houseId
            let isSectionExpanded = expansionStateDict[addressId, default: false]

            let header: AddressesListDataItem = .header(
                identity: .header(addressId: addressId),
                address: address.address,
                isExpanded: isSectionExpanded
            )

            let doors: [AddressesListDataItem] = {
                guard isSectionExpanded else { return [] }

                return address.doors.map { door in
                    let identity = AddressesListDataItemIdentity.offlineDoor(
                        addressId: addressId,
                        domophoneId: door.domophoneId
                    )

                    let vm = OfflineDoorCodeCellViewModel(
                        title: door.name,
                        code: door.code
                    )

                    return .offlineDoor(identity: identity, viewModel: vm)
                }
            }()

            return AddressesListSectionModel(
                identity: addressId,
                items: [header] + doors
            )
        }

        if sectionModels.isEmpty {
            sectionModels = [
                AddressesListSectionModel(
                    identity: "EmptyStateSection",
                    items: [.emptyState]
                )
            ]
        }

        return sectionModels
    }
}
