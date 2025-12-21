//
//  ManagedEntity.swift
//  SmartYard
//
//  Created by Александр Попов on 18.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import CoreData

protocol ManagedEntity where Self: NSManagedObject {
    static var entityName: String { get }
}

extension ManagedEntity {
    static var entityName: String { String(describing: Self.self) }
}
