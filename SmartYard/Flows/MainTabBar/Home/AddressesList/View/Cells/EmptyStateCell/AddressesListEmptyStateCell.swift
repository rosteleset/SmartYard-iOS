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
    @IBOutlet private weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    private func configureUI() {
        titleLabel.text = L10n.Home.AddressesEmpty.listIsEmpty
        subtitleLabel.text = L10n.Home.AddressesEmpty.toAddAnAddressTapAtTheTop
    }

    enum State {
        case online, offline

        var text: String {
            switch self {
            case .online: L10n.Home.AddressesEmpty.onlineTitle
            case .offline: L10n.Home.AddressesEmpty.offlineTitle
            }
        }
    }

    func configure(with state: State) {
        subtitleLabel.text = state.text
    }

}
