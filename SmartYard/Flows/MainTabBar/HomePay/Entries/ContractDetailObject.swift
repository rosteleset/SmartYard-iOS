//
//  ContractDetailObject.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 13.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit

struct ContractDetailObject: Equatable {
    var fromDay: Date
    var toDay: Date
    var details: [DetailObject]
    var isLoaded: Bool = false
}
