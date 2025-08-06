//
//  GateAccessShortcutCell.swift
//  SmartYard
//
//  Created by Александр Попов on 13.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit

class GateAccessShortcutCell: UICollectionViewCell {
    
    // MARK: - Reuse Identifier
    
    static let reuseIdentifier = "GateAccessShortcutCell"
    
    // MARK: - Outlets
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    // MARK: - Configuration

    func configure(with type: GateAccessShortcutType) {
        titleLabel.text = type.title
    }

}
