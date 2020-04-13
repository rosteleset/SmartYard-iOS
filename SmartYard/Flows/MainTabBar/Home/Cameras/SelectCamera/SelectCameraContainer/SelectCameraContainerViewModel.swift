//
//  SelectCameraContainerViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 13.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class SelectCameraContainerViewModel: BaseViewModel {
    
}

extension SelectCameraContainerViewModel {
    
    struct Input {
        let confirmByCourierTapped: Driver<Void>
        let confirmInOfficeTrigger: Driver<Void>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let offices: Driver<[APIOffice]>
    }
    
}
