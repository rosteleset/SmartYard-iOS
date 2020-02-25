//
//  AddressesDataItemIdentity.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

enum AddressesListDataItemIdentity: Hashable {
    
    case header(addressId: String)
    case object(domophoneId: String, doorId: Int, entrance: String?)
    case cameras(addressId: String)
    
}
