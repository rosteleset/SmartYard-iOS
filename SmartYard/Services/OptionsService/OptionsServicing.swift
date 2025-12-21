//
//  OptionsServicing.swift
//  SmartYard
//
//  Created by Александр Попов on 21.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxSwift

protocol OptionsServicing {
    var optionsUpdated: Observable<Void> { get }      // UI слушает
    var didLoadOnce: Bool { get }                     // для логики
    
    func loadIfNeeded(reason: OptionsLoadReason)
    func forceReload(reason: OptionsLoadReason)
}
