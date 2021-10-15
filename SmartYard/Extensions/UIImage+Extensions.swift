//
//  UIImage+Extensions.swift
//  SmartYard
//
//  Created by admin on 04/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

extension UIImage {
    
    func darkened(by value: CGFloat = 2) -> UIImage? {
        return adjustExposure(adjustment: -value)
    }
    
    func brightened(by value: CGFloat = 2) -> UIImage? {
        return adjustExposure(adjustment: value)
    }
    
    private func adjustExposure(adjustment: CGFloat) -> UIImage? {
        guard let inputImage = CIImage(image: self),
            let filter = CIFilter(name: "CIExposureAdjust") else {
            return nil
        }
        
        // The inputEV value on the CIFilter adjusts exposure (negative values darken, positive values brighten)
        filter.setValue(inputImage, forKey: "inputImage")
        filter.setValue(adjustment, forKey: "inputEV")
        
        let context = CIContext(options: nil)
        
        // Break early if the filter was not a success (.outputImage is optional in Swift)
        guard let filteredImage = filter.outputImage,
            let newImage = context.createCGImage(filteredImage, from: filteredImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: newImage)
    }
    
    public convenience init?(base64URLString: String) {
        let previewURL = base64URLString.replacingOccurrences(of: "\\/", with: "/")
        
        if previewURL.hasPrefix("data:image/jpeg;base64,") {
            let base64Data = previewURL.removingPrefix("data:image/jpeg;base64,")
            
            guard let data = Data(base64Encoded: base64Data, options: .ignoreUnknownCharacters) else {
                return nil
            }
            
            self.init(data: data)
            
        } else {
            return nil
        }
    }
    
}
