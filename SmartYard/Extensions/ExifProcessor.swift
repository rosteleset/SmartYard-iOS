//
//  ExifProcessor.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 09.10.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Kingfisher

struct ExifProcessor: ImageProcessor {
    
    var dateCache: NSCache<NSString, NSDate>
    var urlString: String
    
    var identifier: String { "me.layka.exifProcessor" }
    
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            let img = UIImage(data: data)
            if let cgImage = CGImageSourceCreateWithData(data as CFData, nil),
               let metaDict = CGImageSourceCopyPropertiesAtIndex(cgImage, 0, nil) as? NSDictionary,
               let exifDict = metaDict.object(forKey: kCGImagePropertyExifDictionary) as? NSDictionary,
               let exifDate = exifDict[kCGImagePropertyExifDateTimeOriginal] as? String {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                formatter.timeZone = TimeZone(identifier: "GMT")
                if let date = formatter.date(from: exifDate) {
                    dateCache.setObject(date as NSDate, forKey: urlString as NSString)
                }
            }
            return img
        }
    }
}
