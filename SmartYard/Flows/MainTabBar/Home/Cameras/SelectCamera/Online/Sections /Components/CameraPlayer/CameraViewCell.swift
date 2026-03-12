//
//  CameraCollectionViewCell.swift
//  SmartYard
//
//  Created by Александр Попов on 27.01.2024.
//  Copyright © 2024 LanTa. All rights reserved.
//

import UIKit
import SnapKit

final class CameraViewCell: UICollectionViewCell, PlayerAttachable {
    private let shadowContainerView = UIView()
    let playerContainerView = UIView()

    private var currentCameraId: CameraID?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: CameraViewCellModel) {
        currentCameraId = item.id
    }
}

private extension CameraViewCell {
    func configureUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .black
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        shadowContainerView.layer.cornerRadius = 12
        shadowContainerView.layer.masksToBounds = false
        shadowContainerView.layer.shadowColor = UIColor.black.cgColor
        shadowContainerView.layer.shadowOpacity = 0.15
        shadowContainerView.layer.shadowRadius = 8
        shadowContainerView.layer.shadowOffset = CGSize(width: 4, height: 4)

        contentView.addSubview(shadowContainerView)
        shadowContainerView.addSubview(playerContainerView)

        shadowContainerView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
            $0.height.equalTo(contentView.snp.width).multipliedBy(9.0 / 16.0)
        }

        playerContainerView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
}
