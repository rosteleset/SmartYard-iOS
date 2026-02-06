//
//  HasDisposeBag.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import Foundation
import RxSwift

protocol HasDisposeBag: AnyObject {
    var disposeBag: DisposeBag { get }
}

private var disposeBagKey: UInt8 = 0

extension HasDisposeBag {
    var disposeBag: DisposeBag {
        get {
            if let bag = objc_getAssociatedObject(self, &disposeBagKey) as? DisposeBag {
                return bag
            }
            let bag = DisposeBag()
            objc_setAssociatedObject(self, &disposeBagKey, bag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return bag
        }
        set {
            objc_setAssociatedObject(self, &disposeBagKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

