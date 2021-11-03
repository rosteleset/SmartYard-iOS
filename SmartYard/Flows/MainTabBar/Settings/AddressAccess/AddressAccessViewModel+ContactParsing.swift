//
//  AddressAccessViewModel+ContactParsing.swift
//  SmartYard
//
//  Created by admin on 17/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import Contacts
import RxSwift
import RxCocoa

extension AddressAccessViewModel {
    
    func getContacts() -> [CNContact] {
        let contactStore = CNContactStore()
        
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey,
            CNContactImageDataAvailableKey,
            CNContactThumbnailImageDataKey
        ] as [Any]
        
        var allContainers: [CNContainer] = []
        
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        
        var results: [CNContact] = []
        
        allContainers.forEach { container in
            guard let keys = keysToFetch as? [CNKeyDescriptor] else {
                return
            }
            
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            
            do {
                let containerResults = try contactStore.unifiedContacts(
                    matching: fetchPredicate,
                    keysToFetch: keys
                )
                
                results.append(contentsOf: containerResults)
            } catch {
                print("Error fetching containers")
            }
        }
        
        return results
    }
    
    func findContact(matchingNumber number: String, inList list: [CNContact]) -> CNContact? {
        let rawNumber = number.rawPhoneNumberFromFullNumber
        
        let match = list.first { contact in
            contact.phoneNumbers.contains { $0.value.stringValue.rawPhoneNumberFromFullNumber == rawNumber }
        }
        
        return match
    }
    
    func fillAllowedPersonsWithContactData(
        _ persons: [AllowedPerson],
        contactList list: [CNContact]
    ) -> [AllowedPerson] {
        return persons.map {
            guard let match = findContact(matchingNumber: $0.rawNumber, inList: list) else {
                return $0
            }
            
            let icon: UIImage? = {
                if match.imageDataAvailable, let imageData = match.thumbnailImageData {
                    return UIImage(data: imageData)
                } else {
                    return nil
                }
            }()
            
            let nameToShow: String? = {
                let joinedName = [match.givenName, match.familyName]
                    .joined(separator: " ")
                    .trimmed
                
                return joinedName.isEmpty ? nil : joinedName
            }()
            
            return AllowedPerson(
                roommateType: $0.roommateType,
                displayedName: nameToShow,
                rawNumber: $0.rawNumber,
                logoImage: icon
            )
        }
    }
    
}
