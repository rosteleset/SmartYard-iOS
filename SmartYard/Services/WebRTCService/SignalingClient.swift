//
//  SignallingClient.swift
//  SmartYard
//
//  Created by Александр Васильев on 09.11.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

//
//  SignalClient.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import Foundation
import WebRTC

protocol SignalClientDelegate: AnyObject {
    func signalClientDidConnect(_ signalClient: SignalingClient)
    func signalClientDidDisconnect(_ signalClient: SignalingClient)
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription)
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate)
}

final class SignalingClient {
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    weak var delegate: SignalClientDelegate?
    
    init() {
    }
    
    func sendOfferByWHEP(sdp rtcSdp: RTCSessionDescription, url: URL, _ completion: @escaping (_ answerSdp: RTCSessionDescription) -> Void ) {
        
        let message = Message.sdp(SessionDescription(from: rtcSdp))
        let payload = message.sdpPayload
        
        var request = URLRequest(url: url)
        let postBody = payload.data(using: .utf8)
        request.setValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        request.httpBody = postBody
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            
            let sdpAnswer = String(decoding: data, as: UTF8.self)
            let sessionDescription = RTCSessionDescription(type: .answer, sdp: sdpAnswer)
            completion(sessionDescription)
        }
        task.resume()
    }
    
    func send(sdp rtcSdp: RTCSessionDescription, endpointURL: URL) {
        sendOfferByWHEP(sdp: rtcSdp, url: endpointURL) { [weak self] sessionDescription in
            guard let self = self else { return }
            self.delegate?.signalClient(self, didReceiveRemoteSdp: sessionDescription)
        }
    }
    
    func send(candidate rtcIceCandidate: RTCIceCandidate) {
        let message = Message.candidate(IceCandidate(from: rtcIceCandidate))
        print(message.sdpPayload)
    }
}
