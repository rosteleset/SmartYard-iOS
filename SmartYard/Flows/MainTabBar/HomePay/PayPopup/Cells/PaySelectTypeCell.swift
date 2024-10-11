//
//  PaySelectTypeCell.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 16.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit

class PaySelectTypeCell: UICollectionViewCell {
    
    @IBOutlet private weak var selectView: UIView!

    weak var delegate: PayTypeCellProtocol?

    private func setup() {
        selectView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapView(_:)))
        selectView.addGestureRecognizer(tapGesture)
    }

    @objc func handleTapView(_ sender: UITapGestureRecognizer) {
        self.delegate?.didTapSelectView(for: self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}
