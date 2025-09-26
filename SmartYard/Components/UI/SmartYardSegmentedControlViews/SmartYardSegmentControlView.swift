//
//  SmartYardSegmentControlView.swift
//  SmartYard
//
//  Created by Александр Попов on 24.09.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PinLayout

final class SmartYardSegmentControlView: UIView, SmartYardSegmentControlViewProtocol {

    let segmentControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl()
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        segmentControl.backgroundColor = .clear
        segmentControl.selectedSegmentTintColor = .SmartYard.secondBackgroundColor
        segmentControl.layer.borderWidth = 0

        let selectedControlFont = UIFont.SourceSansPro.semibold(size: 18)
        let unselectedControlFont = UIFont.SourceSansPro.regular(size: 18)

        segmentControl.setTitleTextAttributes(
            [
                NSAttributedString.Key.font: unselectedControlFont,
                NSAttributedString.Key.foregroundColor: UIColor.SmartYard.gray
            ],
            for: .normal
        )
        segmentControl.setTitleTextAttributes(
            [
                NSAttributedString.Key.font: selectedControlFont,
                NSAttributedString.Key.foregroundColor: UIColor.SmartYard.semiBlack
            ],
            for: .selected
        )

        return segmentControl
    }()

    var titles: [String] = [] {
        didSet {
            guard !titles.isEmpty else {
                return
            }

            setup()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        addSubview(segmentControl)
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        segmentControl.layerCornerRadius = 12
        NSLayoutConstraint.activate(
            [
                segmentControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
                segmentControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
                segmentControl.topAnchor.constraint(equalTo: topAnchor, constant: 4),
                segmentControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
            ]
        )

        titles.enumerated().forEach { offset, element in
            segmentControl.insertSegment(
                withTitle: element,
                at: offset,
                animated: true
            )
        }

        segmentControl.selectedSegmentIndex = 0
    }
}

