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
    
    fileprivate let segmentControl: UISegmentedControl = {
        let control = UISegmentedControl()
        control.backgroundColor = .white
        control.tintColor = .white
        
        if #available(iOS 13.0, *) {
            control.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 1)
            control.selectedSegmentTintColor = UIColor(red: 255, green: 255, blue: 255, alpha: 1)
            control.layer.borderWidth = 0
        }
        
        let selectedControlFont = UIFont.SourceSansPro.semibold(size: 18)
        let unselectedControlFont = UIFont.SourceSansPro.regular(size: 18)
        
        control.setTitleTextAttributes(
            [
                NSAttributedString.Key.font: unselectedControlFont,
                NSAttributedString.Key.foregroundColor: UIColor.SmartYard.gray
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
    
    private let bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.SmartYard.blue
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let bottomSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0xF3F4FA)!
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var bottomBarWidthAnchor: NSLayoutConstraint?
    private var bottomBarLeftAnchor: NSLayoutConstraint?
    
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
        
        bottomBarLeftAnchor = bottomBar.leftAnchor
            .constraint(equalTo: segmentControl.leftAnchor)
        
        bottomBarLeftAnchor?.isActive = true
        
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
    
    @objc private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        let segmentWidth = self.segmentControl.frame.width / CGFloat(self.segmentItems.count)
        let selectedSegmentIndex = self.segmentControl.selectedSegmentIndex
        let originX = segmentWidth * CGFloat(selectedSegmentIndex)
        
        self.bottomBarLeftAnchor?.constant = originX
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.layoutIfNeeded()
        }
    }
    
}

extension Reactive where Base: SmartYardSegmentedControl {
    
    var selectedIndex: ControlProperty<Int> {
        return base.segmentControl.rx.selectedSegmentIndex
    }
    
}
