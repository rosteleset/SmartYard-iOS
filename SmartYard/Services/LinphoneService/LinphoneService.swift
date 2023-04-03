//
//  LinphoneService.swift
//  sip lanta
//
//  Created by Antol Peshkov on 28/12/2019.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import linphonesw
import UIKit
import CallKit

class LinphoneService: CoreDelegate {
    
    private(set) var core: Core?
    private var timer: Timer?
    
    weak var delegate: LinphoneDelegate?
    
    var hasEnqueuedCalls = false
    
    func onAccountRegistrationStateChanged(core: Core, account: Account, state: RegistrationState, message: String) {
        delegate?.onAccountRegistrationStateChanged(lc: core, account: account, state: state, message: message)
    }
    
    func onCallStateChanged(core: Core, call: Call, state: Call.State, message: String) {
        delegate?.onCallStateChanged(lc: core, call: call, cstate: state, message: message)
    }
    
    func start(_ config: SipConfig) {
        stop()
        do {
            let configName = "linphonerc_default"
            let factoryName = "linphonerc_factory"
            
            guard let configTarget = FileManager.default
                .urls(for: .libraryDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent(configName) else {
                fatalError("Unable to write config file to library")
            }
            
            if let configSource = Bundle.main.url(forResource: configName, withExtension: ""),
                !FileManager.default.fileExists(atPath: configTarget.relativePath) {
                do {
                    try FileManager.default.copyItem(at: configSource, to: configTarget)
                } catch {
                    print("Unable to copy config file from bundle to library")
                }
            }
            
            core = try Factory.Instance.createCore(
                configPath: configTarget.relativePath,
                factoryConfigPath: Bundle.main.path(forResource: factoryName, ofType: "") ?? "",
                systemContext: nil
            )
            
            /*
            let log = LoggingService.Instance /*enable liblinphone logs.*/
            log.logLevelMask = 63
            let logManager = LinphoneLoggingServiceManager()
            log.addDelegate(delegate: logManager)
            Factory.Instance.enableLogCollection(state: .Enabled)
            */
            
            if let core = core {
                let stun = config.stun ?? "none:"
                let params = stun.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
                let typeString = String(params[0])
                let serverString = String(params[1])
            
                let nat = try? core.natPolicy ?? core.createNatPolicy()
                if let natPolicy = nat {
                    natPolicy.stunServer = serverString
                    switch typeString {
                    case "stun":
                        natPolicy.iceEnabled = true
                        natPolicy.stunEnabled = true
                        natPolicy.turnEnabled = false
                    case "turn":
                        natPolicy.iceEnabled = true
                        natPolicy.stunEnabled = false
                        natPolicy.turnEnabled = true
                        
                        switch config.transport {
                        case .Udp:
                            natPolicy.udpTurnTransportEnabled = true
                        case .Tcp:
                            natPolicy.tcpTurnTransportEnabled = true
                        case .Tls:
                            natPolicy.tlsTurnTransportEnabled = true
                        default: break
                        }
                    default:
                        natPolicy.iceEnabled = false
                        natPolicy.stunEnabled = false
                        natPolicy.turnEnabled = false
                    }
                    core.natPolicy = natPolicy
                }
            
                core.callkitEnabled = config.useCallKit
                
                try core.start()
                
                core.clearAllAuthInfo()
                core.clearAccounts()
                
                core.addDelegate(delegate: self)
                
                timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
                    self.core?.iterate()
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        
        try? core?.currentCall?.terminate()
        
        core?.removeDelegate(delegate: self)
        core?.stop()
        core = nil
    }
    
    func connect(config: SipConfig) {
        start(config)
        
        guard let core = core,
              let params = try? core.createAccountParams()
        else {
            return
        }
        
        params.setAccountConfiguration(core: core, configuration: config)
        
        if let authInfo = try? Factory.Instance.createAuthInfo(
            username: config.username,
            userid: nil,
            passwd: config.password,
            ha1: nil,
            realm: nil,
            domain: config.domain
        ) {
            core.addAuthInfo(info: authInfo)
        }
        
        core.useInfoForDtmf = false
        core.useRfc2833ForDtmf = true
        /*
        core.audioPayloadTypes.forEach {
            _ = $0.enable(enabled: true)
        }
        core.videoPayloadTypes.forEach {
            _ = $0.enable(enabled: $0.mimeType == "H264")
        }
        */
        
        try? core.setVideodevice(newValue: "StaticImage: Static picture")
    }
    
    func setViews(videoView: UIView, cameraView: UIView) {
        guard let core = core else {
            return
        }
        
        let videoViewPointer = UnsafeMutableRawPointer(mutating: bridge(obj: videoView))
        core.nativeVideoWindowId = videoViewPointer
        
        let cameraViewPointer = UnsafeMutableRawPointer(mutating: bridge(obj: cameraView))
        core.nativePreviewWindowId = cameraViewPointer
    }
    
    private func bridge<T: AnyObject>(obj: T) -> UnsafeRawPointer {
        let pointer = Unmanaged.passUnretained(obj).toOpaque()
        return UnsafeRawPointer(pointer)
    }
    
}

class LinphoneLoggingServiceManager: LoggingServiceDelegate {
    func onLogMessageWritten(logService: LoggingService, domain: String, level: LogLevel, message: String) {
        print("Logging service log: \(message) \n")
    }
    
}
