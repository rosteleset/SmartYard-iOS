//
//  IncomingCallStateContainer.swift
//  SmartYard
//
//  Created by admin on 14.07.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable line_length

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
    
    /// Определяет режим Динамика по-умолчанию.
    /// для CallKit он всегда выключен, а для обычного режима - зависит от настроек пользователя.
    static func getDefaultSpeakerMode(_ isCallKitUsed: Bool, apiWrapper: APIWrapper) -> IncomingCallStateContainer {
        
        if isCallKitUsed {
            return .initial
        } else {
            let speakerEnabledByDefault = apiWrapper.accessService.prefersSpeakerForCalls
            
            let configuredSoundOutputState = speakerEnabledByDefault ? IncomingCallSoundOutputState.speaker : IncomingCallSoundOutputState.regular
            
            return .init(
                callState: IncomingCallStateContainer.initial.callState,
                doorState: IncomingCallStateContainer.initial.doorState,
                previewState: IncomingCallStateContainer.initial.previewState,
                soundOutputState: configuredSoundOutputState
            )
        }
    }
    
}
