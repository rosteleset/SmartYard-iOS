//
//  IncomingCallViewModel+Extensions.swift
//  SmartYard
//
//  Created by admin on 18/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension IncomingCallViewModel {
    
    struct Input {
        let previewTrigger: Driver<Void>
        
        // MARK: Ну я хз, придется либо прокидывать вьюхи сюда, либо UnsafeRawPointer. И то, и то - говно
        
        let callTrigger: Driver<Void>
        let videoViewsTrigger: Driver<(UIView, UIView, UIView)>
        let ignoreTrigger: Driver<Void>
        let openTrigger: Driver<Void>
        let speakerTrigger: Driver<Void>
        let viewWillAppear: Driver<IncomingCallScreenType>
    }
    
    struct Output {
        let state: Driver<IncomingCallStateContainer>
        let subtitle: Driver<String?>
        let image: Driver<UIImage?>
        let isDoorBeingOpened: Driver<Bool>
    }
    
}
