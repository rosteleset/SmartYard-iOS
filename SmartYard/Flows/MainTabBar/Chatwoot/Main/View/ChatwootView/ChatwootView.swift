//
//  ServiceFromCourierView.swift
//  SmartYard
//
//  Created by Mad Brains on 11.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import PMNibLinkableView
import RxSwift
import RxCocoa

class ChatwootView: PMNibLinkableView {
    
    @IBOutlet fileprivate weak var chatButton: BlueButton!
    
}

extension Reactive where Base: ChatwootView {
    
    var chatButtonTapped: ControlEvent<Void> {
        return base.chatButton.rx.tap
    }
    
}
