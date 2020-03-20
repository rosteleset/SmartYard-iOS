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
        let rawNumbers = contact.phoneNumbers.compactMap {
            $0.value.stringValue.rawPhoneNumberFromFullNumber
        }
        
        guard let firstMatchingRawNumber = rawNumbers.first else {
            dismiss(animated: true)
            return
        }
        
        contactNameLabel.text = contact.givenName
        
        let nameToShow: String = {
            [contact.givenName, contact.familyName]
                .joined(separator: " ")
                .trimmed
        }()
        
        var allowedPerson = AllowedPerson(
            displayedName: nameToShow,
            rawNumber: firstMatchingRawNumber,
            logoImage: nil
        )
        
        if contact.imageDataAvailable, let imageData = contact.thumbnailImageData {
            let image = UIImage(data: imageData)
            contactImageView.image = image
            allowedPerson.logoImage = image
        }
        
        addAccessButton.isEnabled = true
        textField.isHidden = true
        contactNameLabel.isHidden = false
        
        newContactTrigger.onNext(allowedPerson)
    }

}
