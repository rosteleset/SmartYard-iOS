//
//  HistoryTableViewCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 23.03.2021.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import UIKit

final class HistoryLoadingTableViewCell: UITableViewCell {
    
    @IBOutlet private var loader: UIActivityIndicatorView!
    
    var isLoading = true {
        didSet {
            if isLoading {
                loader.startAnimating()
            } else {
                loader.stopAnimating()
            }
        }
    }
    
}
