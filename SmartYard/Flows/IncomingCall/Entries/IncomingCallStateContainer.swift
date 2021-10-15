//
//  IncomingCallStateContainer.swift
//  SmartYard
//
//  Created by admin on 14.07.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct IncomingCallStateContainer {
    
    let callState: IncomingCallState
    let doorState: IncomingCallDoorState
    let previewState: IncomingCallPreviewState
    let soundOutputState: IncomingCallSoundOutputState
    
    static var initial: IncomingCallStateContainer {
        return .init(
            callState: .callReceived,
            doorState: .notDetermined,
            previewState: .staticImage,
            soundOutputState: .regular
        )
    }
    
}
