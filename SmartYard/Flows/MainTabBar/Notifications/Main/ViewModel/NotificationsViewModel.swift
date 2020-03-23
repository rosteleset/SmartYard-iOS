//
//  NotificationsViewModel.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class NotificationsViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    
    init(apiWrapper: APIWrapper) {
        self.apiWrapper = apiWrapper
    }
    
}
