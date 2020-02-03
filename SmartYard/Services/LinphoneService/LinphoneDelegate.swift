//
//  LinphoneDelegate.swift
//  sip lanta
//
//  Created by admin on 27/01/2020.
//  Copyright © 2020 Тарас Евченко. All rights reserved.
//

import linphonesw
import UIKit

protocol LinphoneDelegate: AnyObject {
    
    func onRegistrationStateChanged(lc: Core, cfg: ProxyConfig, cstate: RegistrationState, message: String)
    func onCallStateChanged(lc: Core, call: Call, cstate: Call.State, message: String)
    
}
