//
//  HeaderView.swift
//  SmartYard
//
//  Created by Александр Попов on 16.09.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit
import PMNibLinkableView

final class HeaderView: PMNibLinkableView {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBInspectable var titleNumberOfLines: Int = 2 {
        didSet { titleLabel?.numberOfLines = titleNumberOfLines }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.numberOfLines = titleNumberOfLines
    }

    func setText(_ title: String, subtitle: String = "") {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle.isEmpty
    }
    
}
