//
//  MediaDataItem.swift
//  SmartYard
//
//  Created by devcentra on 07.04.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation
import MessageKit

struct MediaDataItem: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

extension MediaDataItem {
    
    init(imageurl: String?, placeholderurl: String) {
        self.url = URL(string: imageurl)
        
        self.placeholderImage = UIImage()
        if let thumbUrl = URL(string: placeholderurl),
           let thumbData = try? Data(contentsOf: thumbUrl) {
            self.placeholderImage = UIImage(data: thumbData)!
        }
        self.size = self.placeholderImage.size
    }
    
}
