//
//  AddressesListObjectCell.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class OfflineDoorCodeCell: CustomBorderCollectionViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var codeLabel: UILabel!
    
    func configure(with item: OfflineDoorCodeCellViewModel) {
        titleLabel.text = item.title
        codeLabel.text = item.code
    }
}
