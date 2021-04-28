//
//  HistoryTableViewCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 23.03.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class HistoryLoadingTableViewCell: UITableViewCell {
    
    @IBOutlet private var loader: UIActivityIndicatorView!
    
    var isLoading: Bool = true {
        didSet {
            if isLoading {
                loader.startAnimating()
            } else {
                loader.stopAnimating()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
