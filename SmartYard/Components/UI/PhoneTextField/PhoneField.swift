//
//  PhoneField.swift
//  SmartYard
//
//  Created by Александр Васильев on 27.12.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

import Foundation
import UIKit

final class PhoneField: UIView {
    
    private let prefixLabel = UILabel()
    
    var numberViewsCollection = [NumberFieldView]()
    var gapBeforeDigit: [Bool]
    
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
        prefixLabel.textColor = UIColor(named: "gray")
        prefixLabel.font = UIFont.SourceSansPro.bold(size: 36)
        prefixLabel.sizeToFit()
        prefixLabel.height = 34
        
        for _ in 0...AccessService.shared.phoneLengthWithoutPrefix - 1 {
            numberViewsCollection.append(PhoneField.createNumView())
        }
        addSubview(prefixLabel)
        numberViewsCollection.forEach { self.addSubview($0) }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        prefixLabel.pin.left(5).vCenter()
        
        numberViewsCollection.enumerated().forEach { num, view in
            switch num {
            case 0:
                view.pin.after(of: prefixLabel, aligned: .center).marginLeft(12)
            case let value where gapBeforeDigit[value]:
                view.pin.after(of: numberViewsCollection[num - 1], aligned: .center).marginLeft(12)
            default:
                view.pin.after(of: numberViewsCollection[num - 1], aligned: .center).marginLeft(2)
            }
        }
    }
}
