//
//  AddressesDataItemIdentity.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

enum AddressesListDataItemIdentity: Hashable {
    case header(addressId: String)
    case object(addressId: String, domophoneId: String, doorId: Int, entrance: String?)
    case doorPreviewPager(addressId: String)
    case cameras(addressId: String)
    case history(addressId: String)
    case serviceExtension(addressId: String, extId: String)
    case unapprovedObject(issueId: String, address: String)
    case emptyState

    case offlineDoor(addressId: String, domophoneId: String)
}
