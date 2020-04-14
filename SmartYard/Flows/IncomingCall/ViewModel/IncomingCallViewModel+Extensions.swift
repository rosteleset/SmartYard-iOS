//
//  IncomingCallViewModel+Extensions.swift
//  SmartYard
//
//  Created by admin on 18/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension IncomingCallViewModel {
    
    struct Input {
        let previewTrigger: Driver<Void>
        
        // MARK: Ну я хз, придется либо прокидывать вьюхи сюда, либо UnsafeRawPointer. И то, и то - говно
        
        let callTrigger: Driver<(UIView, UIView)>
        let ignoreTrigger: Driver<Void>
        let openTrigger: Driver<Void>
    }
    
    struct Output {
        let state: Driver<(IncomingCallState, IncomingCallDoorState)>
        let subtitle: Driver<String?>
        let image: Driver<UIImage?>
        let isDoorBeingOpened: Driver<Bool>
    }
    
}
