//
//  PhoneDialing.swift
//  SmartYard
//
//  Created by Codex on 04.03.2026.
//

import UIKit

protocol PhoneDialing {
    func call(_ phoneNumber: String)
}

final class SystemPhoneDialer: PhoneDialing {
    func call(_ phoneNumber: String) {
        guard let phoneCallURL = URL(string: "tel://\(phoneNumber)") else {
            return
        }

        let application = UIApplication.shared
        guard application.canOpenURL(phoneCallURL) else {
            return
        }

        application.open(phoneCallURL, options: [:], completionHandler: nil)
    }
}
