//
//  SmartYardSharedObject.swift
//  SmartYardSharedDataFramework
//
//  Created by Mad Brains on 09.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

public struct SmartYardSharedObject: Codable, Hashable {
   
    public var objectName: String
    public var objectAddress: String
    public var domophoneId: String
    public var doorId: Int
    public var blockReason: String?
    public var logoImageName: String
    
    public init(
        objectName: String,
        objectAddress: String,
        domophoneId: String,
        doorId: Int,
        blockReason: String?,
        logoImageName: String
    ) {
        self.objectName = objectName
        self.objectAddress = objectAddress
        self.domophoneId = domophoneId
        self.doorId = doorId
        self.blockReason = blockReason
        self.logoImageName = logoImageName
    }
    
}
