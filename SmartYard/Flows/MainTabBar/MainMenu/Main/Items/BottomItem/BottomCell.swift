//
//  BottomCell.swift
//  SmartYard
//
//  Created by Александр Васильев on 26.01.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import SnapKit
import UIKit

final class BottomCell: UICollectionViewCell {

    private let iconImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "CallMenuIcon"))
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()

    private let titleLabel = UILabel.make(
        LabelConfig(
            font: .SourceSansPro.regular(size: 18),
            color: .SmartYard.blue,
            alignment: .natural,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            adjustsFontSizeToFitWidth: true,
            minimumScaleFactor: 0.75
        ),
        text: L10n.Menu.Support.callToTechSupport
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Not supported") }

    private func configureUI() {
        layerCornerRadius = 12
        addBorder(dynamicColor: .SmartYard.blue)

        contentView.addSubview(iconImageView) { make in
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.size.equalTo(28)
        }

        contentView.addSubview(titleLabel) { make in
            make.centerY.equalTo(iconImageView)
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerX.equalToSuperview().offset(20).priority(.high)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }
    }
}
