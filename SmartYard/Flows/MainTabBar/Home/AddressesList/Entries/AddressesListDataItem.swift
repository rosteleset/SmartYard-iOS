//
//  AddressesDataItem.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxDataSources

enum AddressesListDoorPreviewSource: Equatable {
    case image(urlString: String)
    case video(urlString: String)

    var urlString: String {
        switch self {
        case .image(let urlString), .video(let urlString):
            return urlString
        }
    }
}

struct AddressesListDoorPreviewItem: Equatable {
    let identity: AddressesListDataItemIdentity
    let title: String
    let subtitle: String?
    let iconImageName: String
    let previewSource: AddressesListDoorPreviewSource?
    let hasCamera: Bool
    let isOpened: Bool
}

enum AddressesListDataItem: IdentifiableType, Equatable {
    
    case header(identity: AddressesListDataItemIdentity, address: String, isExpanded: Bool)
    case object(identity: AddressesListDataItemIdentity, type: DomophoneObjectType, name: String, isOpened: Bool)
    case doorPreviewPager(identity: AddressesListDataItemIdentity, items: [AddressesListDoorPreviewItem])
    case doorPreview(
        identity: AddressesListDataItemIdentity,
        title: String,
        subtitle: String?,
        previewSource: AddressesListDoorPreviewSource?,
        hasCamera: Bool,
        isOpened: Bool
    )
    case cameras(identity: AddressesListDataItemIdentity, numberOfCameras: Int)
    case history(identity: AddressesListDataItemIdentity, numberOfEvents: Int)
    case extensionItem(
        identity: AddressesListDataItemIdentity,
        caption: String,
        iconURL: String,
        isHighlighted: Bool
    )
    case unapprovedAddresses(identity: AddressesListDataItemIdentity, address: String)
    case emptyState

    case offlineDoor(identity: AddressesListDataItemIdentity, viewModel: OfflineDoorCodeCellViewModel)

}

extension AddressesListDataItem {
    
    var identity: AddressesListDataItemIdentity {
        switch self {
        case .header(let identity, _, _):
            return identity
        case .object(let identity, _, _, _):
            return identity
        case .doorPreviewPager(let identity, _):
            return identity
        case .doorPreview(let identity, _, _, _, _, _):
            return identity
        case .cameras(let identity, _):
            return identity
        case .history(let identity, _):
            return identity
        case .extensionItem(let identity, _, _, _):
            return identity
        case .unapprovedAddresses(let identity, _):
            return identity
        case .emptyState:
            return .emptyState
        case .offlineDoor(let identity, _):
            return identity
        }
    }
    
}
