//
//  OffertaCell.swift
//  SmartYard
//
//  Created by devcentra on 16.02.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit

class OffertaCell: UITableViewCell {

    @IBOutlet weak var checkBox: UISwitch!
    @IBOutlet weak var offertaUrl: UIButton!
    
    private var currentState: Bool = false {
        didSet {
            checkBox.setOn(currentState, animated: true)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with text: String, state: Bool = false) {
        currentState = state
        offertaUrl.setTitle(text, for: .normal)
    }
    
}
