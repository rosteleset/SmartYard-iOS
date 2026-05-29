//
//  AddressesListViewModel+Sections.swift
//  SmartYard
//
//  Created by Александр Попов on 21.04.2026.
//

import Foundation

extension AddressesListViewModel {

    // swiftlint:disable:next function_body_length
    func createSections(
        approvedAddressesData: GetAddressListResponseData,
        unapprovedAddressesData: GetListConnectResponseData,
        camMapData: CamMapCCTVResponseData,
        expansionStateDict: [String: Bool],
        objectAccessDict: [AddressesListDataItemIdentity: Bool],
        shouldShowEntrancePreviews: Bool
    ) -> [AddressesListSectionModel] {
        // swiftlint:disable:next closure_body_length
        var sectionModels = approvedAddressesData.map { address -> AddressesListSectionModel in
            let addressId = address.houseId
            let isSectionExpanded = expansionStateDict[addressId, default: false]

            let header: AddressesListDataItem = .header(
                identity: .header(addressId: addressId),
                address: address.address,
                isExpanded: isSectionExpanded
            )

            let objects: [AddressesListDataItem] = {
                guard isSectionExpanded else {
                    return []
                }

                let doorItems = address.doors.map { door -> AddressesListDataItem in
                    let identity = makeDoorIdentity(addressId: addressId, door: door)

                    return .object(
                        identity: identity,
                        type: door.type,
                        name: door.name,
                        isOpened: objectAccessDict[identity, default: false]
                    )
                }

                let doorPreviewItems = address.doors.map { door -> AddressesListDoorPreviewItem in
                    let identity = makeDoorIdentity(addressId: addressId, door: door)

                    let camera = resolveCamera(for: door, camMap: camMapData)

                    return AddressesListDoorPreviewItem(
                        identity: identity,
                        title: door.name,
                        subtitle: makeDoorPreviewSubtitle(for: door),
                        previewSource: makePreviewSource(from: camera),
                        hasCamera: camera != nil,
                        isOpened: objectAccessDict[identity, default: false]
                    )
                }

                let doorPreviewPager: AddressesListDataItem? = {
                    guard !doorPreviewItems.isEmpty else {
                        return nil
                    }

                    return .doorPreviewPager(
                        identity: .doorPreviewPager(addressId: addressId),
                        items: doorPreviewItems
                    )
                }()

                let cameras: AddressesListDataItem? = {
                    guard address.cctv != 0 else {
                        return nil
                    }

                    return .cameras(identity: .cameras(addressId: addressId), numberOfCameras: address.cctv)
                }()

                let history: AddressesListDataItem? = {
                    if address.hasPlog == false {
                        return nil
                    }
                    return .history(identity: .history(addressId: addressId), numberOfEvents: 0)
                }()

                let entranceItems = shouldShowEntrancePreviews ? [doorPreviewPager].compactMap { $0 } : doorItems
                return entranceItems + [cameras, history].compactMap { $0 }
            }()

            return AddressesListSectionModel(
                identity: addressId,
                items: [header] + objects
            )
        }

        let unapprovedAddressItems = unapprovedAddressesData.compactMap { issueInfo -> AddressesListDataItem? in
            guard let address = issueInfo.address else {
                return nil
            }

            return .unapprovedAddresses(
                identity: .unapprovedObject(issueId: issueInfo.key, address: address),
                address: address
            )
        }

        unapprovedAddressItems.forEach {
            sectionModels.append(AddressesListSectionModel(identity: String($0.identity.hashValue), items: [$0]))
        }

        if sectionModels.isEmpty {
            sectionModels.append(
                AddressesListSectionModel(identity: "EmptyStateSection", items: [.emptyState])
            )
        }

        return sectionModels
    }

    func resolveDoor(
        identity: AddressesListDataItemIdentity,
        in addresses: GetAddressListResponseData
    ) -> (address: APIAddress, door: APIDoor)? {
        guard case let .object(addressId, domophoneId, doorId, _) = identity,
              let address = addresses.first(where: { $0.houseId == addressId }),
              let door = address.doors.first(where: {
                  $0.domophoneId == domophoneId && $0.doorId == doorId
              })
        else {
            return nil
        }

        return (address, door)
    }

    func makeDoorIdentity(addressId: String, door: APIDoor) -> AddressesListDataItemIdentity {
        AddressesListDataItemIdentity.object(
            addressId: addressId,
            domophoneId: door.domophoneId,
            doorId: door.doorId,
            entrance: door.entrance
        )
    }

    func resolveCamera(
        for door: APIDoor,
        camMap: CamMapCCTVResponseData
    ) -> CameraObject? {
        guard let domophoneId = Int(door.domophoneId) else {
            return nil
        }

        guard let mappedCamera = camMap.first(where: { $0.id == domophoneId }) else {
            return nil
        }

        return CameraObject(
            id: mappedCamera.id,
            position: Constants.defaultMapCenterCoordinates,
            cameraNumber: 1,
            name: door.name,
            video: mappedCamera.url,
            token: mappedCamera.token,
            serverType: mappedCamera.serverType,
            hlsMode: mappedCamera.hlsMode,
            hasSound: mappedCamera.hasSound
        )
    }

    func makePreviewSource(from camera: CameraObject?) -> AddressesListDoorPreviewSource? {
        guard let camera else {
            return nil
        }

        switch camera.serverType {
        case .macroscop, .trassir, .forpost:
            return .image(urlString: camera.previewURL)
        case .flussonic, .nimble:
            return .video(urlString: camera.previewURL)
        }
    }

    func makeDoorPreviewSubtitle(for door: APIDoor) -> String? {
        guard let entrance = door.entrance?.trimmingCharacters(in: .whitespacesAndNewlines),
              !entrance.isEmpty,
              entrance != door.name
        else {
            return nil
        }

        return entrance
    }
}
