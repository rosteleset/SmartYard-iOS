//
//  LinphoneService.swift
//  sip lanta
//
//  Created by Antol Peshkov on 28/12/2019.
//  Copyright © 2019 Тарас Евченко. All rights reserved.
//

import Foundation
import linphonesw
import UIKit
import CallKit

// swiftlint:disable all
class LinphoneService: CoreDelegate {
    
    private(set) var core: Core? = nil
    private var timer: Timer? = nil
    
    weak var delegate: LinphoneDelegate?
    
    var hasEnqueuedCalls = false
    
    override func onRegistrationStateChanged(lc: Core, cfg: ProxyConfig, cstate: RegistrationState, message: String) {
        delegate?.onRegistrationStateChanged(lc: lc, cfg: cfg, cstate: cstate, message: message)
    }
    
    override func onCallStateChanged(lc: Core, call: Call, cstate: Call.State, message: String) {
        delegate?.onCallStateChanged(lc: lc, call: call, cstate: cstate, message: message)
    }
    
    func start() {
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
            
            try core?.start()
            
            core?.clearAllAuthInfo()
            core?.clearProxyConfig()
            
            core?.addDelegate(delegate: self)
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
                self.core?.iterate()
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
        start()
        
        guard let core = core else {
            return
        }
        
        let accountCreator = try! core.createAccountCreator(xmlrpcUrl: "")
        accountCreator.setAccountConfiguration(config)
        
        let cfg = try! accountCreator.createProxyConfig()
        
        if let stun = config.stun {
            
            print("stunServer = \(stun)")
            print("natPolicy = \(core.natPolicy.debugDescription)")
            
            let params = stun.split(separator: ":", maxSplits: 1)
            
            let typeString = String(params[0])
            let serverString = String(params[1])
      
            try! core.natPolicy = core.createNatPolicy()
            
            core.natPolicy?.stunServer = serverString
            
            switch typeString {
            case "stun":
                core.natPolicy?.stunEnabled = true
            case "turn":
                core.natPolicy?.turnEnabled = true
                
                switch config.transport {
                case .Udp:
                    core.natPolicy?.udpTurnTransportEnabled = true
                case .Tcp:
                    core.natPolicy?.tcpTurnTransportEnabled = true
                case .Tls:
                    core.natPolicy?.tlsTurnTransportEnabled = true
                default: break
                }
            default: break
            }
            core.natPolicy?.resolveStunServer()
            
            core.stunServer = serverString
        }

        
        try! core.addProxyConfig(config: cfg)
        
        core.useInfoForDtmf = false
        core.useRfc2833ForDtmf = true

        core.audioPayloadTypes.forEach {
            _ = $0.enable(enabled: true)
        }
        
        core.videoPayloadTypes.forEach {
            _ = $0.enable(enabled: $0.mimeType == "H264")
        }
        
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
    
    private func bridge<T: AnyObject>(obj : T) -> UnsafeRawPointer {
        let pointer = Unmanaged.passUnretained(obj).toOpaque()
        return UnsafeRawPointer(pointer)
    }
    
}
