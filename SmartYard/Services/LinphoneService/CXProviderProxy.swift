//
//  ProviderDelegate.swift
//  SmartYard
//
//  Created by admin on 06.07.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import PushKit
import CallKit
import linphonesw
import AVKit

protocol CXProviderProxyDelegate: AnyObject {
    
    func providerDidEndCall(_ provider: CXProvider)
    func providerDidAnswerCall(_ provider: CXProvider)
    
    func provider(_ provider: CXProvider, didActivateAudioSession audioSession: AVAudioSession)
    func provider(_ provider: CXProvider, didDeactivateAudioSession audioSession: AVAudioSession)
    
}

class CXProviderProxy: NSObject {
    
    private let provider: CXProvider
    
    weak var delegate: CXProviderProxyDelegate?

    override init() {
        provider = CXProvider(configuration: CXProviderProxy.providerConfiguration)
        
        super.init()
        
        provider.setDelegate(self, queue: nil)
    }
    
    static var providerConfiguration: CXProviderConfiguration = {
        let providerConfiguration = CXProviderConfiguration(
            localizedName: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "SmartYard"
        )
        
        providerConfiguration.supportsVideo = true
        providerConfiguration.supportedHandleTypes = [.generic]
        providerConfiguration.iconTemplateImageData = UIImage(named: "LantaSquareLogo")?.pngData()

        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1
        
        return providerConfiguration
    }()

    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool, completion: @escaping () -> Void) {
        let update = CXCallUpdate()
        
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.hasVideo = hasVideo
        
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsHolding = false
        update.supportsDTMF = false
        
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if error == nil {
                
            } else {
                
            }
            completion()
        }
    }

    func updateCall(uuid: UUID, handle: String, hasVideo: Bool) {
        let update = CXCallUpdate()
        
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.hasVideo = hasVideo
        
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsHolding = false
        update.supportsDTMF = false
        
        provider.reportCall(with: uuid, updated: update)
    }
    
    func endCall(uuid: UUID) {
        provider.reportCall(with: uuid, endedAt: .init(), reason: .declinedElsewhere)
    }
    
}

extension CXProviderProxy: CXProviderDelegate {
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        delegate?.providerDidEndCall(provider)
        
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        delegate?.providerDidAnswerCall(provider)
        
        action.fulfill()
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        action.fulfill()
    }
    
    func providerDidReset(_ provider: CXProvider) {
        
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        delegate?.provider(provider, didActivateAudioSession: audioSession)
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        delegate?.provider(provider, didDeactivateAudioSession: audioSession)
    }
    
}
