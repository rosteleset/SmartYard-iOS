//
//  CameraNumberCell.swift
//  SmartYard
//
//  Created by Mad Brains on 30.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class CameraNumberCell: UICollectionViewCell {
     weak var delegate: CameraButtonDelegate?
     
     private let buttonSize = CGSize(width: 36, height: 36)
     private let maxColumns: Int = 5
     
     var buttons: [CameraButton] = []

     private func setupContainerView() -> UIView {
          let containerView = UIView()
          containerView.translatesAutoresizingMaskIntoConstraints = false
          contentView.addSubview(containerView)
          containerView.layoutIfNeeded()
          
          NSLayoutConstraint.activate([
               containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
               containerView.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: 20
               ),
               containerView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -20
               ),
               containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
               containerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
               containerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
         ])
          
         return containerView
     }
     
     func resetSelection() {
          for button in buttons {
               button.isSelected = false
          }
     }
     
     func selectCameraButton(cameraNumber: Int) {
         guard let buttonIndex = buttons.firstIndex(where: { $0.cameraNumber == cameraNumber }) else {
             return
         }
          
         buttons.forEach { $0.isSelected = false }
         
         buttons[buttonIndex].isSelected = true
     }
     
     func configure(with cameraObjects: [CameraObject], rows: Int, selectedCameraNumber: Int) {
          contentView.subviews.forEach { $0.removeFromSuperview() }
          buttons = []
          let containerView = setupContainerView()
          containerView.layoutIfNeeded()
          
          let containerViewHeight = self.height
          print(containerViewHeight)
         
          let buttonOffset = (self.width - 40 - buttonSize.width) / CGFloat(maxColumns - 1)
          let buttonInset = buttonOffset - buttonSize.width
          let spacingBetweenRows: CGFloat = rows > 1 ? (containerViewHeight - CGFloat(rows) * buttonSize.height) / CGFloat(rows - 1) : 0
          
          var currentRow = 0
          var currentColumn = 0
          
          for cameraObject in cameraObjects {
               let button = CameraButton(cameraNumber: cameraObject.cameraNumber)
               button.delegate = self
               buttons.append(button)
               
               containerView.addSubview(button)
               
               NSLayoutConstraint.activate([
                    button.widthAnchor.constraint(equalToConstant: buttonSize.width),
                    button.heightAnchor.constraint(equalToConstant: buttonSize.height),
                    button.topAnchor.constraint(
                         equalTo: containerView.topAnchor,
                         constant: CGFloat(currentRow) * (buttonSize.height + spacingBetweenRows)
                    ),
                    button.leadingAnchor.constraint(
                         equalTo: containerView.leadingAnchor,
                         constant: CGFloat(currentColumn) * buttonOffset
                    )
               ])
               
               currentColumn += 1
               if currentColumn >= maxColumns {
                    currentColumn = 0
                    currentRow += 1
               }
          }
          selectCameraButton(cameraNumber: selectedCameraNumber)
     }
 }

extension CameraNumberCell: CameraButtonDelegate {
     func didTapCameraButton(cameraNumber: Int) {
          buttons.forEach { $0.isSelected = false }
          
          if let button = buttons.first(where: { $0.cameraNumber == cameraNumber }) {
              button.isSelected = true
          }
     
          delegate?.didTapCameraButton(cameraNumber: cameraNumber)
     }
}
