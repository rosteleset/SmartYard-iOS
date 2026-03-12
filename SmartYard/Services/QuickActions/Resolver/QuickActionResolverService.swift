//
//  QuickActionResolverService.swift
//  SmartYard
//
//  Created by Александр Попов on 27.02.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import RxSwift

final class QuickActionResolverService {
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let timeout: RxTimeInterval

    init(
        apiWrapper: APIWrapper,
        accessService: AccessService = .shared,
        timeout: RxTimeInterval = .seconds(3)
    ) {
        self.apiWrapper = apiWrapper
        self.accessService = accessService
        self.timeout = timeout
    }

    func resolve(_ shortcutType: AppShortcutType) -> Single<QuickActionResolution> {
        switch shortcutType {
        case .firstAddressCameras:
            return resolveFirstAddressCameras()
        case .firstAddressEvents:
            return resolveFirstAddressEvents()
        case .firstAddressAccess:
            return resolveFirstAddressAccess()
        default:
            return .just(
                .unavailable(
                    message: L10n.QuickAction.Error.unsupported
                )
            )
        }
    }
}

private extension QuickActionResolverService {
    func resolveFirstAddressCameras() -> Single<QuickActionResolution> {
        apiWrapper.getAddressList(forceRefresh: false)
            .timeout(timeout, scheduler: MainScheduler.instance)
            .flatMap { [self] addresses -> Single<QuickActionResolution> in
                let sortedAddresses = sortedAddresses(addresses ?? [])

                guard let address = sortedAddresses.first else {
                    return .just(
                        .unavailable(
                            message: L10n.QuickAction.FirstAddress.noAddresses
                        )
                    )
                }

                guard address.cctv > 0 else {
                    return .just(
                        .unavailable(
                            message: L10n.QuickAction.FirstAddress.noCameras
                        )
                    )
                }

                if accessService.showList {
                    return .just(
                        .target(
                            .homeCamerasMap(
                                houseId: address.houseId,
                                address: address.address,
                                cameras: nil
                            )
                        )
                    )
                }

                return apiWrapper.getAllTreeCCTV(houseId: address.houseId, forceRefresh: false)
                    .timeout(timeout, scheduler: MainScheduler.instance)
                    .map { response in
                        guard let response else {
                            return .unavailable(
                                message: L10n.QuickAction.FirstAddress.camerasNotFound
                            )
                        }

                        if response.type == .map {
                            let cameras: [CameraObject] = (response.cameras ?? [])
                                .enumerated()
                                .map { offset, element in
                                    CameraObject(
                                        id: element.id,
                                        position: element.coordinate,
                                        cameraNumber: offset + 1,
                                        name: element.name,
                                        video: element.video,
                                        token: element.token,
                                        serverType: element.serverType,
                                        hlsMode: element.hlsMode,
                                        hasSound: element.hasSound
                                    )
                                }

                            return .target(
                                .homeCamerasMap(
                                    houseId: address.houseId,
                                    address: address.address,
                                    cameras: cameras
                                )
                            )
                        }

                        return .target(
                            .homeCamerasList(
                                houseId: address.houseId,
                                address: address.address,
                                tree: response
                            )
                        )
                    }
            }
    }

    func resolveFirstAddressEvents() -> Single<QuickActionResolution> {
        apiWrapper.getAddressList(forceRefresh: false)
            .timeout(timeout, scheduler: MainScheduler.instance)
            .map { [self] addresses -> QuickActionResolution in
                let sortedAddresses = sortedAddresses(addresses ?? [])

                guard let address = sortedAddresses.first else {
                    return .unavailable(
                        message: L10n.QuickAction.FirstAddress.noAddresses
                    )
                }

                guard address.hasPlog else {
                    return .unavailable(
                        message: L10n.QuickAction.FirstAddress.noEvents
                    )
                }

                return .target(
                    .homeEvents(
                        houseId: address.houseId,
                        address: address.address
                    )
                )
            }
    }

    func resolveFirstAddressAccess() -> Single<QuickActionResolution> {
        apiWrapper.getSettingsAddresses(forceRefresh: false)
            .timeout(timeout, scheduler: MainScheduler.instance)
            .map { [self] addresses -> QuickActionResolution in
                let sortedAddresses = sortedSettingsAddresses(addresses ?? [])

                guard let address = sortedAddresses.first else {
                    return .unavailable(
                        message: L10n.QuickAction.FirstAddress.noAddresses
                    )
                }

                guard let flatId = address.flatId else {
                    return .unavailable(
                        message: L10n.QuickAction.FirstAddress.noAccessSettings
                    )
                }

                return .target(
                    .menuAddressAccess(
                        address: address.address,
                        flatId: flatId,
                        clientId: address.clientId
                    )
                )
            }
    }

    func sortedAddresses(_ addresses: GetAddressListResponseData) -> GetAddressListResponseData {
        let savedOrder = accessService.userPreferredAddressOrder

        guard !savedOrder.isEmpty else {
            let alphabetic = addresses.sorted {
                $0.address.localizedCaseInsensitiveCompare($1.address) == .orderedAscending
            }
            let withDoors = alphabetic.filter { !$0.doors.isEmpty }
            let withoutDoors = alphabetic.filter { $0.doors.isEmpty }

            return withDoors + withoutDoors
        }

        return addresses.sorted { first, second in
            let firstIndex = savedOrder.firstIndex(of: first.houseId) ?? Int.max
            let secondIndex = savedOrder.firstIndex(of: second.houseId) ?? Int.max

            if firstIndex != secondIndex {
                return firstIndex < secondIndex
            }

            return first.address.localizedCaseInsensitiveCompare(second.address) == .orderedAscending
        }
    }

    func sortedSettingsAddresses(_ addresses: GetSettingsListResponseData) -> GetSettingsListResponseData {
        let savedOrder = accessService.userPreferredAddressOrder

        return addresses.sorted { first, second in
            let firstHouseId = first.houseId ?? ""
            let secondHouseId = second.houseId ?? ""

            let firstIndex = savedOrder.firstIndex(of: firstHouseId) ?? Int.max
            let secondIndex = savedOrder.firstIndex(of: secondHouseId) ?? Int.max

            if firstIndex != secondIndex {
                return firstIndex < secondIndex
            }

            return first.address.localizedCaseInsensitiveCompare(second.address) == .orderedAscending
        }
    }
}
