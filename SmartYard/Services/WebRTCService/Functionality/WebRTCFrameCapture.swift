//
//  WebRTCFrameCapture.swift
//  SmartYard
//
//  Created by Александр Попов on 18.12.2024.
//  Copyright © 2024 Sesameware. All rights reserved.
//

import WebRTC
import UIKit

final class WebRTCFrameCapture: NSObject, RTCVideoRenderer {
    private var isFrameCaptured = false
    var frameCapturedCallback: ((UIImage?) -> Void)?

    func setSize(_ size: CGSize) {

    }

    func renderFrame(_ frame: RTCVideoFrame?) {
        guard !isFrameCaptured, let frame = frame else { return }
        
        isFrameCaptured = true

        if let image = frameToImage(frame) {
            frameCapturedCallback?(image)
        } else {
            frameCapturedCallback?(nil)
        }
    }

    private func frameToImage(_ frame: RTCVideoFrame) -> UIImage? {
        guard let buffer = frame.buffer as? RTCCVPixelBuffer else { return nil }
        
        let ciImage = CIImage(cvPixelBuffer: buffer.pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
    
}
