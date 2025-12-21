//
//  AddressesListEmptyStateCell.swift
//  SmartYard
//
//  Created by admin on 16.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

final class AddressesListEmptyStateCell: UICollectionViewCell {

    @IBOutlet private weak var subtitleLabel: UILabel!

    enum State {
        case online, offline

        var text: String {
            switch self {
            case .online: NSLocalizedString("List Empty Online List", comment: "")
            case .offline: NSLocalizedString("List Empty Offline List", comment: "")
            }
        }
    }

    func configure(with state: State) {
        subtitleLabel.text = state.text
    }

}
