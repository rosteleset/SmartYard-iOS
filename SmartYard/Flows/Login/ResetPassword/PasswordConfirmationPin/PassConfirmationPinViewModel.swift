//
//  PassConfirmationPinViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 23.03.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCoordinator

class PassConfirmationPinViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<HomeRoute>
    
    init(apiWrapper: APIWrapper, router: WeakRouter<HomeRoute>, selectedContact: String?) {
        self.apiWrapper = apiWrapper
        self.router = router
    }
    
}
