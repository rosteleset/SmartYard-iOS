//
//  SmartYardSegmentedControlView.swift
//  SmartYard
//
//  Created by Mad Brains on 11.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit

class SmartYardSegmentedControl: UIView {
    
    let daysSegmentControl: UISegmentedControl = {
        let control = UISegmentedControl()
        control.backgroundColor = .clear
        control.tintColor = .clear
        
        let selectedControlFont = UIFont.SourceSansPro.semibold(size: 18)
        let unselectedControlFont = UIFont.SourceSansPro.regular(size: 18)
        
        control.setTitleTextAttributes(
            [
                NSAttributedString.Key.font: unselectedControlFont,
                NSAttributedString.Key.foregroundColor: UIColor.SmartYard.placeholderGrayText
            ],
            for: .normal
        )
        
        control.setTitleTextAttributes(
            [
                NSAttributedString.Key.font: selectedControlFont,
                NSAttributedString.Key.foregroundColor: UIColor.SmartYard.semiBlack
            ],
            for: .selected
        )
        
        control.translatesAutoresizingMaskIntoConstraints = false
        
        return control
    }()
    
    let bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.SmartYard.blue
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var segmentItems: [String] = [] {
        didSet {
            guard !segmentItems.isEmpty else {
                return
            }
            
            setup()
            bottomBarWidthAnchor?.isActive = false
            
            bottomBarWidthAnchor = bottomBar.widthAnchor.constraint(
                equalTo: daysSegmentControl.widthAnchor,
                multiplier: 1 / CGFloat(segmentItems.count)
            )
            
            bottomBarWidthAnchor?.isActive = true
        }
    }
    
    var bottomBarWidthAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        guard !segmentItems.isEmpty else {
            return
        }
        
        addSubview(daysSegmentControl)
        addSubview(bottomBar)
        
        daysSegmentControl.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        daysSegmentControl.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        daysSegmentControl.topAnchor.constraint(equalTo: topAnchor).isActive = true
        daysSegmentControl.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        daysSegmentControl.addTarget(
            self,
            action: #selector(segmentedControlValueChanged(_:)),
            for: .valueChanged
        )
        
        bottomBar.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        bottomBar.heightAnchor.constraint(equalToConstant: 2).isActive = true
        bottomBar.leftAnchor.constraint(equalTo: daysSegmentControl.leftAnchor).isActive = true
        
        bottomBarWidthAnchor = bottomBar.widthAnchor.constraint(
            equalTo: daysSegmentControl.widthAnchor,
            multiplier: 1 / CGFloat(segmentItems.count)
        )
        
        bottomBarWidthAnchor?.isActive = true
        
        setupSegmentItems()
    }
    
    private func setupSegmentItems() {
        segmentItems.enumerated().forEach { offset, element in
            daysSegmentControl.insertSegment(
                withTitle: element,
                at: offset,
                animated: true
            )
        }
        
        daysSegmentControl.selectedSegmentIndex = 0
    }
    
    @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else {
                return
            }
            
            let segmentWidth = self.daysSegmentControl.frame.width / CGFloat(self.segmentItems.count)
            let selectedSegmentIndex = self.daysSegmentControl.selectedSegmentIndex
            let originX = segmentWidth * CGFloat(selectedSegmentIndex)
            
            self.bottomBar.frame.origin.x = originX
        }
    }
    
}
