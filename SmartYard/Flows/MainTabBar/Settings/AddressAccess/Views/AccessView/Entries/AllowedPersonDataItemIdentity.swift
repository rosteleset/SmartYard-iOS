//
//  AllowedPersonDataItemIdentity.swift
//  SmartYard
//
//  Created by admin on 19/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

enum AllowedPersonDataItemIdentity: Hashable {
    
    case addContact
    case contact(person: AllowedPerson)
    
}
