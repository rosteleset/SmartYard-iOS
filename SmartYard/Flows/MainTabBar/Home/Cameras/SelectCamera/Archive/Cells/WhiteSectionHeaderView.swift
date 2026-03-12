//
//  WhiteSectionHeaderView.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-05-16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//
import UIKit
import JTAppleCalendar

final class WhiteSectionHeaderView: JTACMonthReusableView {
    
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var separatorViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var localizedMonLabel: UILabel!
    @IBOutlet private weak var localizedTueLabel: UILabel!
    @IBOutlet private weak var localizedWedLabel: UILabel!
    @IBOutlet private weak var localizedThuLabel: UILabel!
    @IBOutlet private weak var localizedFriLabel: UILabel!
    @IBOutlet private weak var localizedSatLabel: UILabel!
    @IBOutlet private weak var localizedSunLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    private func configureUI() {
        localizedMonLabel.text = L10n.Common.Weekday.Short.mon
        localizedTueLabel.text = L10n.Common.Weekday.Short.tue
        localizedWedLabel.text = L10n.Common.Weekday.Short.wed
        localizedThuLabel.text = L10n.Common.Weekday.Short.thu
        localizedFriLabel.text = L10n.Common.Weekday.Short.fri
        localizedSatLabel.text = L10n.Common.Weekday.Short.sat
        localizedSunLabel.text = L10n.Common.Weekday.Short.sun
    }
    
}
