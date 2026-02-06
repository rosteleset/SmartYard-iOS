//
//  CameraNumberCell.swift
//  SmartYard
//
//  Created by Mad Brains on 30.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

final class CameraNumberCell: UICollectionViewCell {
     private let cameraNumberLabel = UILabel()
     private let circleView = UIView()

     override var isSelected: Bool {
          didSet {
               circleView.backgroundColor = isSelected ? UIColor.SmartYard.blue : .white
               cameraNumberLabel.textColor = isSelected ? .white : UIColor.SmartYard.semiBlack
          }
     }

     override init(frame: CGRect = .zero) {
          super.init(frame: frame)
          setupUI()
     }
     
     required init?(coder: NSCoder) {
          fatalError("init(coder:) has not been implemented")
     }

     override func layoutSubviews() {
          super.layoutSubviews()
          circleView.layerCornerRadius = frame.width / 2
     }

     func configure(with item: CameraNumberCellViewModel) {
          cameraNumberLabel.text = item.title
     }
}

private extension CameraNumberCell {
     func setupUI() {
          cameraNumberLabel.font = UIFont.SourceSansPro.semibold(size: 16)

          circleView.layerBorderWidth = 1
          circleView.layerBorderColor = UIColor.SmartYard.blue
          circleView.layerCornerRadius = frame.width / 2

          contentView.addSubview(circleView)
          circleView.addSubview(cameraNumberLabel)

          circleView.snp.makeConstraints {
               $0.directionalEdges.equalToSuperview()
          }
          cameraNumberLabel.snp.makeConstraints {
               $0.center.equalToSuperview()
          }
     }
}
