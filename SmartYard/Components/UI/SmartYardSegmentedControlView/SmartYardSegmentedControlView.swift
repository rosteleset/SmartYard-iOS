//
//  SmartYardSegmentedControlView.swift
//  SmartYard
//
//  Created by Mad Brains on 11.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class SmartYardSegmentedControl: UIView {
    
    let segmentControl: UISegmentedControl = {
        let control = UISegmentedControl()
        control.backgroundColor = .white
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
    
    let bottomSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0xF3F4FA)!
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
                equalTo: segmentControl.widthAnchor,
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
        
        addSubview(segmentControl)
        addSubview(bottomSeparator)
        addSubview(bottomBar)
        
        configureSegmentControlAnchors()
        configureBottomBarAnchors()
        configureSeparatorAnchors()
        
        bottomBarWidthAnchor?.isActive = true
        
        segmentControl.addTarget(
            self,
            action: #selector(segmentedControlValueChanged(_:)),
            for: .valueChanged
        )
        
        setupSegmentItems()
    }
    
    private func configureSegmentControlAnchors() {
        segmentControl.widthAnchor
            .constraint(equalTo: widthAnchor)
            .isActive = true
        
        segmentControl.centerXAnchor
            .constraint(equalTo: centerXAnchor)
            .isActive = true
        
        segmentControl.topAnchor
            .constraint(equalTo: topAnchor)
            .isActive = true
        
        segmentControl.bottomAnchor
            .constraint(equalTo: bottomAnchor)
            .isActive = true
    }
    
    private func configureBottomBarAnchors() {
        bottomBar.bottomAnchor
            .constraint(equalTo: bottomAnchor)
            .isActive = true
        
        bottomBar.heightAnchor
            .constraint(equalToConstant: 2)
            .isActive = true
        
        bottomBar.leftAnchor
            .constraint(equalTo: segmentControl.leftAnchor)
            .isActive = true
        
        bottomBarWidthAnchor = bottomBar.widthAnchor.constraint(
            equalTo: segmentControl.widthAnchor,
            multiplier: 1 / CGFloat(segmentItems.count)
        )
    }
    
    private func configureSeparatorAnchors() {
        bottomSeparator.bottomAnchor
            .constraint(equalTo: bottomAnchor)
            .isActive = true
        
        bottomSeparator.heightAnchor
            .constraint(equalToConstant: 1)
            .isActive = true
        
        bottomSeparator.leftAnchor
            .constraint(equalTo: segmentControl.leftAnchor)
            .isActive = true
        
        bottomSeparator.rightAnchor
            .constraint(equalTo: segmentControl.rightAnchor)
            .isActive = true
    }
    
    private func setupSegmentItems() {
        segmentItems.enumerated().forEach { offset, element in
            segmentControl.insertSegment(
                withTitle: element,
                at: offset,
                animated: true
            )
        }
        
        segmentControl.selectedSegmentIndex = 0
    }
    
    @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else {
                return
            }
            
            let segmentWidth = self.segmentControl.frame.width / CGFloat(self.segmentItems.count)
            let selectedSegmentIndex = self.segmentControl.selectedSegmentIndex
            let originX = segmentWidth * CGFloat(selectedSegmentIndex)
            
            self.bottomBar.frame.origin.x = originX
        }
    }
    
}

extension Reactive where Base: SmartYardSegmentedControl {
    
    var selectedIndexControlProperty: ControlProperty<Int> {
        return base.segmentControl.rx.selectedSegmentIndex
    }
    
}
