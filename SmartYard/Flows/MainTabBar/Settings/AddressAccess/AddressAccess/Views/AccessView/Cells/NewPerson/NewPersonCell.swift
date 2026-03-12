//
//  NewPersonCell.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

final class NewPersonCell: UITableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    private func configureUI() {
        titleLabel.text = L10n.Settings.AddressAccess.NewPerson.addContact
    }

}
