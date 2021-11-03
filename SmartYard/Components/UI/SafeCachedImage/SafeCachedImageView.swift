//
//  SafeCachedImageView.swift
//  SmartYard
//
//  Created by Александр Васильев on 26.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class SafeCachedImageView: UIImageView {

    private var imageUrlString: String?
    private var loadingImageIndicator: UIActivityIndicatorView?
    
    func loadImageUsingUrlString(urlString: String,
                                 cache: NSCache<NSString, UIImage>,
                                 label: UILabel? = nil,
                                 errorMessage: String = "",
                                 rect: CGRect? = nil,
                                 rectColor: UIColor = .clear) {
        
        imageUrlString = urlString
        
        self.image = nil
        
        if let imageFromCache = cache.object(forKey: NSString(string: urlString)) {
            self.image = imageFromCache
            
            label?.text = ""
            if let rect = rect {
                self.drawRectangle(rect: rect, rectColor: rectColor)
            }
            return
        }
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        if loadingImageIndicator == nil {
            loadingImageIndicator = UIActivityIndicatorView(style: .gray)
        }
        
        loadingImageIndicator!.center = view.center
        view.addSubview(loadingImageIndicator!)
        loadingImageIndicator!.startAnimating()
        self.backgroundColor = UIColor(named: "backgroundColor")
        
        URLSession.shared.dataTask(
            with: url,
            completionHandler: { data, response, _ in
                DispatchQueue.main.async {
                    self.loadingImageIndicator!.stopAnimating()
                    self.loadingImageIndicator!.removeFromSuperview()
                    self.backgroundColor = .clear
                }
                
                guard
                    let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                    let data = data,
                    let loadedImage = UIImage(data: data)
                else {
                    DispatchQueue.main.async {
                        if self.imageUrlString == urlString {
                            label?.text = errorMessage
                        }
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    if self.imageUrlString == urlString {
                        self.image = loadedImage
                        label?.text = ""
                        if let rect = rect {
                            self.drawRectangle(rect: rect, rectColor: rectColor)
                        }
                    }
                    cache.setObject(loadedImage, forKey: NSString(string: urlString))
                }
            }
        )
            .resume()
    }
    
    func drawRectangle(rect: CGRect, rectColor: UIColor) {
        guard let image = self.image else {
            return
        }
        
        let imageSize = image.size
        let scale: CGFloat = self.contentScaleFactor
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(3.0)
        
        image.draw(at: CGPoint.zero)

        rectColor.setStroke()
        let transform = CGAffineTransform(scaleX: 1 / scale, y: 1 / scale)
        UIRectFrame(rect.applying(transform))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if newImage != nil {
            self.image = newImage
        }
    }
    
}
