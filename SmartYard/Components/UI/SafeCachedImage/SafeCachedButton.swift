//
//  SafeCachedImageView.swift
//  SmartYard
//
//  Created by Александр Васильев on 26.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class SafeCachedButton: UIButton {

    private var imageUrlString: String?
    private var loadingImageIndicator: UIActivityIndicatorView?
    
    func loadImageUsingUrlString(
        urlString: String,
        cache: NSCache<NSString, UIImage>,
        label: UILabel? = nil,
        errorMessage: String = ""
    ) {
        imageUrlString = urlString
        
        self.setImage(nil, for: .normal)
        
        if let imageFromCache = cache.object(forKey: NSString(string: urlString)) {
            self.setImage(imageFromCache, for: .normal)
            label?.text = ""
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
                        self.setImage(loadedImage, for: .normal)
                        label?.text = ""
                    }
                    cache.setObject(loadedImage, forKey: NSString(string: urlString))
                }
            }
        )
            .resume()
        
    }

}
