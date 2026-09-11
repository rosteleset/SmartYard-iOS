//
//  SmartYardSharedData.swift
//  SmartYardSharedDataFramework
//
//  Created by Mad Brains on 09.04.2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import Foundation

public struct SmartYardSharedData: Codable {
    
    public var accessToken: String
    public var backendURL: String?
    public var sharedObjects: [SmartYardSharedObject]
    
    public init(accessToken: String, backendURL: String, sharedObjects: [SmartYardSharedObject]) {
        self.accessToken = accessToken
        self.backendURL = backendURL
        self.sharedObjects = sharedObjects
    }

}
