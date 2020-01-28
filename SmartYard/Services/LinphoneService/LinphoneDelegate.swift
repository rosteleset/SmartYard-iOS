//
//  LinphoneDelegate.swift
//  sip lanta
//
//  Created by admin on 27/01/2020.
//  Copyright © 2020 Тарас Евченко. All rights reserved.
//

import linphonesw
import UIKit

class LinphoneDelegate : CoreDelegate {
    
//    weak var vc: ViewController?
    
    override func onRegistrationStateChanged(lc: Core, cfg: ProxyConfig, cstate: RegistrationState, message: String) {
//        vc?.updateView(state: cstate)
    }
    
    override func onCallStateChanged(lc: Core, call: Call, cstate: Call.State, message: String) {
        if cstate == .IncomingReceived, let params = try? lc.createCallParams(call: call) {
            params.videoEnabled = true
            params.audioEnabled = true
            
            let alert = UIAlertController(title: "Входящий звонок", message: call.remoteAddressAsString, preferredStyle: .alert)
            
            alert.addAction(
                UIAlertAction(title: "Принять", style: .default) { _ in
                    try? call.acceptWithParams(params: params)
                }
            )
            
            alert.addAction(
                UIAlertAction(title: "Отклонить", style: .cancel) { _ in
                    try? call.decline(reason: .Busy)
                }
            )
            
//            vc?.present(alert, animated: true, completion: nil)
        }
        
//        vc?.updateCallView(state: cstate)
    }
    
}
