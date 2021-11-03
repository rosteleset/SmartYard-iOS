//
//  LinphoneDelegate.swift
//  sip lanta
//
//  Created by admin on 27/01/2020.
//  Copyright © 2020 LanTa. All rights reserved.
//

import linphonesw
import UIKit

protocol LinphoneDelegate: AnyObject {
    
    func onAccountRegistrationStateChanged(lc: Core, account: Account, state: RegistrationState, message: String)
    func onCallStateChanged(lc: Core, call: Call, cstate: Call.State, message: String)
    
}
