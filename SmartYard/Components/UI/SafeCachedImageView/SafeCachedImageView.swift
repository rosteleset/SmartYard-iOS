//
//  SafeCachedImageView.swift
//  SmartYard
//
//  Created by Александр Васильев on 26.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class SafeCachedImageView: UIImageView {

    var imageUrlString: String?
    
    func loadImageUsingUrlString(urlString: String, cache: NSCache<NSString, UIImage>) {
        
        imageUrlString = urlString
        
        self.image = nil
        
        if let imageFromCache = cache.object(forKey: NSString(string: urlString)) {
            self.image = imageFromCache
            return
        }
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTask(
            with: url,
            completionHandler: { (data, response, error) in
                guard
                    let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                    let data = data,
                    let loadedImage = UIImage(data: data)
                    else {
                        return
                }
                
                DispatchQueue.main.async {
                    if self.imageUrlString == urlString {
                        self.image = loadedImage
                    }
                    cache.setObject(loadedImage, forKey: NSString(string: urlString))
                }
            }
        )
            .resume()
        
    }

}
