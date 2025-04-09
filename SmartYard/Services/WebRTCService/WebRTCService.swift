//
//  WebRTCService.swift
//  SmartYard
//
//  Created by Александр Васильев on 09.11.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit
import WebRTC

final class WebRTCService: NSObject {
    private let webRTCClient: WebRTCClient
    private let signalClient: SignalingClient
    private let endpointUrl: URL
    private var _containerView: UIView?
    var stateConnected = false
    var containerView: UIView? {
        get {
            return _containerView
        }
        set {
            _containerView = newValue
            if stateConnected, let containerView = _containerView {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) { [weak self] in
                    containerView.removeSubviews()
                    Logger.logInfo("Binding to containerView while already connected.")
                    self?.bindView(containerView)
                }
            }
        }
    }
    
    init(iceServers: [String], endpointUrl: URL) {
        self.webRTCClient = WebRTCClient(iceServers: iceServers)
        
        self.signalClient = SignalingClient()
        self.endpointUrl = endpointUrl
        
        super.init()
        
        self.webRTCClient.delegate = self
        self.signalClient.delegate = self
        
        self.webRTCClient.offer { sdp in
            self.signalClient.send(sdp: sdp, endpointURL: self.endpointUrl)
        }
    }
    
    func bindView(_ containerView: UIView) {
        let remoteRenderer = RTCMTLVideoView(frame: containerView.frame)
        remoteRenderer.videoContentMode = .scaleAspectFit
        self.webRTCClient.renderRemoteVideo(to: remoteRenderer)
        
        containerView.backgroundColor = .black
        containerView.addSubview(remoteRenderer)
        remoteRenderer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[view]|",
                options: [],
                metrics: nil,
                views: ["view": remoteRenderer]
            )
        )
        
        containerView.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[view]|",
                options: [],
                metrics: nil,
                views: ["view": remoteRenderer]
            )
        )
        containerView.layoutIfNeeded()
        containerView.sendSubviewToBack(remoteRenderer)
    }
    
    func captureFrame(completion: @escaping (UIImage?) -> Void) {
        self.webRTCClient.captureFrame(completion: completion)
    }
    
    func setRemoteSDP(sdp: RTCSessionDescription) {
        self.webRTCClient.set(remoteSdp: sdp) { error in
            if let error = error {
                Logger.logError("Failed to set remote SDP: \(error.localizedDescription)")
            }
        }
    }
    
}

extension WebRTCService: SignalClientDelegate {
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        return
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        return
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        return
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        Logger.logInfo("Received remote sdp")
        Logger.logDebug(sdp.sdp.debugDescription)
        setRemoteSDP(sdp: sdp)
    }
}

extension WebRTCService: WebRTCClientDelegate {
    func webRTCClientHaveLocalOffer(_ client: WebRTCClient) {
        Logger.logDebug("webRTCClientHaveLocalOffer")
    }
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        Logger.logDebug("didDiscoverLocalCandidate: \(candidate.description)")
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        Logger.logInfo("didChangeConnectionState: \(state.description)")
        stateConnected = state == .connected
        if stateConnected, let containerView = self.containerView {
            DispatchQueue.main.async { [weak self] in
                Logger.logInfo("Binding to containerView right after connected")
                self?.bindView(containerView)
            }
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        Logger.logDebug("didReceiveData")
    }
}

