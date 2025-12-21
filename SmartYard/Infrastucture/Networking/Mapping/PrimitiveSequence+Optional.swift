//
//  PrimitiveSequence+Optional.swift
//  SmartYard
//
//  Created by Александр Попов on 21.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxSwift

extension PrimitiveSequence where Trait == SingleTrait {
    func mapToOptional() -> Single<Element?> {
        return map { $0 }
    }
}
