//
//  SafeCachedImageView.swift
//  SmartYard
//
//  Created by Александр Васильев on 26.04.2021.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import UIKit
import AVFoundation

class SafeCachedImageView: UIImageView {
    
    var imageUrlString: String?
    private lazy var loadingImageIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.center = view.center
        self.addSubview(indicator)
        return indicator
    }()
    
    func loadImageUsingUrlString(urlString: String,
                                 cache: NSCache<NSString, UIImage>,
                                 label: UILabel? = nil,
                                 errorMessage: String = "") {
        self.image = nil
        
        loadingImageIndicator.center = self.view.center
        loadingImageIndicator.contentMode = .center
        loadingImageIndicator.startAnimating()
        
        imageUrlString = urlString
        guard let url = URL(string: urlString) else { return }
                
        URLSession.shared.dataTask(with: url) { [weak self] data, response, _ in
            guard let self = self else { return }
            
            // TODO: - сделать здесь скелетон -
            DispatchQueue.main.async {
                guard self.imageUrlString == urlString else { return }
                self.loadingImageIndicator.stopAnimating()
                self.backgroundColor = .black
            }
            
            guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                  let data = data else {
                DispatchQueue.main.async {
                    if self.imageUrlString == urlString {
                        label?.text = errorMessage
                    }
                }
                return
            }
            
            if let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    if self.imageUrlString == urlString {
                        self.image = loadedImage
                        label?.text = ""
                    }
                    cache.setObject(loadedImage, forKey: NSString(string: urlString))
                }
            } else {
                DispatchQueue.global(qos: .userInteractive).async {
                    if let loadedImage = self.imageFromVideo(url: url, at: 1) {
                        DispatchQueue.main.async {
                            if self.imageUrlString == urlString {
                                self.image = loadedImage
                            }
                            cache.setObject(loadedImage, forKey: NSString(string: urlString))
                        }
                    }
                }
            }
        }
        .resume()
    }
    
    func resetImage() {
        if imageUrlString != nil { loadingImageIndicator.stopAnimating() }
        imageUrlString = nil
        image = nil
    }
}

// Понимаю что не относится к классу, пока что для первой реализации оставлю так.
// В будущем нужно вынести отдельно
private extension SafeCachedImageView {
    
    func imageFromVideo(url: URL, at time: TimeInterval) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let assetIG = AVAssetImageGenerator(asset: asset)
        let cmTime = CMTime(seconds: time, preferredTimescale: 60)
        
        assetIG.appliesPreferredTrackTransform = true
        assetIG.apertureMode = .encodedPixels
        
        do {
            let thumbnailImageRef = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
            return UIImage(cgImage: thumbnailImageRef)
        } catch let error {
            Logger.logError("\(error)")
            return nil
        }
    }
    
}
