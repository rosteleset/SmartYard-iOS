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
    let videoState: IncomingCallVideoState
    
    static var initial: IncomingCallStateContainer {
        return .init(
            callState: .callReceived,
            doorState: .notDetermined,
            previewState: .staticImage,
            soundOutputState: .regular,
            videoState: .none
        )
    }
    
    /// Определяет режим динамика по умолчанию.
    /// Для CallKit начальный маршрут остаётся обычным до активации аудиосессии,
    /// чтобы не перехватывать подключённые наушники или другой внешний аудиовыход.
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
                soundOutputState: configuredSoundOutputState,
                videoState: IncomingCallStateContainer.initial.videoState
            )
        }
    }
    
}
