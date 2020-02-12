//
//  AvailableSericesViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 12.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCoordinator

class AvailableSericesViewModel: BaseViewModel {
    
}

extension AvailableSericesViewModel {
    
    struct Input {
        let nextTapped: Driver<Void>
        let serviceStateChanged: Driver<(Int, ServiceState)>
    }
    
    struct Output {
        let serviceItems: Driver<[ServiceModel]>
    }
    
}
