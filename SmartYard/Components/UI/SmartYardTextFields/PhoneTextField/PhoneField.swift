//
//  PhoneField.swift
//  SmartYard
//
//  Created by Александр Васильев on 27.12.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

final class PhoneField: UIView {
    var numberViewsCollection = [NumberFieldView]()
    var gapBeforeDigit: [Bool]

    private let prefixLabel = UILabel()

    private static func setupGapBeforeDigit(_ from: String) -> [Bool] {
        var gapBefore: [Bool] = []
        var previousWasNotDigit = true
        for idx in 0...from.charactersArray.count - 1 {
            if from.charactersArray[idx] == "#" {
                gapBefore.append(previousWasNotDigit)
                previousWasNotDigit = false
            } else {
                previousWasNotDigit = true
            }
        }
        return gapBefore
    }
    
    required init?(coder: NSCoder) {
        gapBeforeDigit = PhoneField.setupGapBeforeDigit(AccessService.shared.phonePattern)
        super.init(coder: coder)
        setupView()
        
    }
    
    override init(frame: CGRect) {
        gapBeforeDigit = PhoneField.setupGapBeforeDigit(AccessService.shared.phonePattern)
        super.init(frame: frame)
        setupView()
    }
    
    override var intrinsicContentSize: CGSize {
        var calculatedWidth: Double = 0.0
        calculatedWidth += 5 + prefixLabel.width
        
        numberViewsCollection.enumerated().forEach { num, view in
            switch num {
            case let value where gapBeforeDigit[value]:
                calculatedWidth += 12 + view.width
            default:
                calculatedWidth += 2 + view.width
            }
        }
        calculatedWidth += 5
        return CGSize(width: calculatedWidth, height: 34)
    }
    
    static func createNumView() -> NumberFieldView {
        guard let view = NumberFieldView.loadFromNib(named: "NumberFieldView") as? NumberFieldView else {
            return NumberFieldView()
        }
        view.width = 22
        view.height = 34
        
        return view
    }
    
    func setupView() {
        prefixLabel.text = "+" + AccessService.shared.phonePrefix
        prefixLabel.textAlignment = .center
        prefixLabel.textColor = UIColor.SmartYard.gray
        prefixLabel.font = UIFont.SourceSansPro.bold(size: 36)
        prefixLabel.sizeToFit()
        prefixLabel.height = 34
        
        for _ in 0...AccessService.shared.phoneLengthWithoutPrefix - 1 {
            numberViewsCollection.append(PhoneField.createNumView())
        }

        addSubview(prefixLabel) { make in
            make.left.equalToSuperview().offset(5)
            make.centerY.equalToSuperview()
            make.width.equalTo(prefixLabel.frame.width)
            make.height.equalTo(34)
        }

        var previousView: UIView = prefixLabel
        numberViewsCollection.enumerated().forEach { num, view in
            let marginLeft: CGFloat = gapBeforeDigit[num] ? 12 : 2

            addSubview(view) { make in
                make.left.equalTo(previousView.snp.right).offset(marginLeft)
                make.centerY.equalTo(prefixLabel)
                make.width.equalTo(22)
                make.height.equalTo(34)
            }
            previousView = view
        }
    }
}
