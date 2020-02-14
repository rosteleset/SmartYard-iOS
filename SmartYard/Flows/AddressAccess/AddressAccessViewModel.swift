//
//  AddressAccessViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa

class AddressAccessViewModel: BaseViewModel {
    
    private let router: WeakRouter<AppRoute>
    
    init(router: WeakRouter<AppRoute>) {
        self.router = router
    }
    
    func transform(input: Input) -> Output {
        
        return Output()
    }
    
}

extension AddressAccessViewModel {
    
    struct Input {

    }
    
    struct Output {
        
    }
    
}
