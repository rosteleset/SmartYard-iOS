//
//  YTCollectionViewCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 17.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Kingfisher
import UIKit

final class YTCollectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var topSeparator: UIView!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var thumbnail: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureCell(label: String, thumbnailUrl: String?, isFirst: Bool) {
        if isFirst {
            self.topSeparator.isHidden = true
        } else {
            self.topSeparator.isHidden = false
        }
        
        self.label.text = label
        
        self.setThumbnail(thumbnailUrl: thumbnailUrl);
    }
    
    private func setThumbnail(thumbnailUrl: String?) {
        if thumbnailUrl == nil {
            return
        }
        
        guard let url = URL(string: thumbnailUrl) else {
            return
        }
        
        self.thumbnail.kf.setImage(with: url)
    }
}
