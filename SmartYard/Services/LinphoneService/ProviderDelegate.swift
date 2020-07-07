//
//  ProviderDelegate.swift
//  SmartYard
//
//  Created by admin on 06.07.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import PushKit
import CallKit
import linphonesw
import AVKit

class CallInfo: NSObject {
    
    var callId: String = ""
    var accepted = false
    var toAddr: Address?
    var isOutgoing = false
    var sasEnabled = false
    var declined = false
    var connected = false
    
    static func newIncomingCallInfo(callId: String) -> CallInfo {
        let callInfo = CallInfo()
        callInfo.callId = callId
        return callInfo
    }
    
    static func newOutgoingCallInfo(addr: Address, isSas: Bool) -> CallInfo {
        let callInfo = CallInfo()
        callInfo.isOutgoing = true
        callInfo.sasEnabled = isSas
        callInfo.toAddr = addr
        return callInfo
    }
    
}

class ProviderDelegate: NSObject {
    
    private let provider: CXProvider
    
    var uuids: [String: UUID] = [:]
    var callInfos: [UUID: CallInfo] = [:]

    override init() {
        provider = CXProvider(configuration: ProviderDelegate.providerConfiguration)
        
        super.init()
        
        provider.setDelegate(self, queue: nil)
    }
    
    static var providerConfiguration: CXProviderConfiguration = {
        let providerConfiguration = CXProviderConfiguration(
            localizedName: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "SmartYard"
        )
        
        providerConfiguration.supportsVideo = false
        providerConfiguration.supportedHandleTypes = [.generic]

        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1
        
        return providerConfiguration
    }()

    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool) {
        let update = CXCallUpdate()
        
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.hasVideo = hasVideo

        let callInfo = callInfos[uuid]
        let callId = callInfo?.callId
        
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if error == nil {
                
            } else {
                
            }
        }
    }

    func updateCall(uuid: UUID, handle: String, hasVideo: Bool = false) {
        let update = CXCallUpdate()
        
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.hasVideo = hasVideo
        
        provider.reportCall(with: uuid, updated: update)
    }
    
    func endCall(uuid: UUID) {
        provider.reportCall(with: uuid, endedAt: .init(), reason: .declinedElsewhere)
    }
    
}

extension ProviderDelegate: CXProviderDelegate {
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        action.fulfill()
    }
    
    func providerDidReset(_ provider: CXProvider) {
        
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        
    }
    
}
