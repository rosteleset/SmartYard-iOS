//
//  OnlineFullscreenCameraCell.swift
//  SmartYard
//
//  Created by Александр Попов on 24.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit

final class OnlineFullscreenCameraCell: UICollectionViewCell, PlayerAttachable {
    let playerContainerView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .black
        contentView.backgroundColor = .black

        playerContainerView.backgroundColor = .black
        contentView.addSubview(playerContainerView)
        playerContainerView.frame = contentView.bounds
        playerContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
