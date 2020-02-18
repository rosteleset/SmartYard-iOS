//
//  NewAllowedPerson+Contacts.swift
//  SmartYard
//
//  Created by Mad Brains on 18.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import ContactsUI
import Contacts

extension NewAllowedPersonViewController: CNContactPickerDelegate {
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let phoneNumberCount = contact.phoneNumbers.count
        
        guard phoneNumberCount > 0 else {
            dismiss(animated: true)
            return
        }
        
        contactNameLabel.text = contact.givenName
        
        var allowedPerson = AllowedPerson(
            displayedName: contact.givenName,
            phoneNumber: getNumberFromContact(contactNumber: contact.phoneNumbers[safe: 0]?.value.stringValue ?? "-"),
            logoImage: nil
        )
        
        if contact.imageDataAvailable {
            let image = UIImage(data: contact.imageData!)
            contactImageView.image = image
            allowedPerson.logoImage = image
        }
        
        newContactTrigger.onNext(allowedPerson)
    }
    
    func getNumberFromContact(contactNumber: String) -> String {
        var contactNumber = contactNumber.replacingOccurrences(of: "-", with: "")
        contactNumber = contactNumber.replacingOccurrences(of: "(", with: "")
        contactNumber = contactNumber.replacingOccurrences(of: ")", with: "")
        
        guard contactNumber.count >= Constants.phoneLengthWithoutPrefix else {
            dismiss(animated: true)
            return ""
        }
        
        return String(contactNumber.suffix(Constants.phoneLengthWithoutPrefix))
    }

}
