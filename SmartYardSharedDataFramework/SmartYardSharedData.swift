//
//  SmartYardSharedData.swift
//  SmartYardSharedDataFramework
//
//  Created by Mad Brains on 09.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

public struct SmartYardSharedData: Codable {
    
    public var accessToken: String
    public var sharedObjects: [SmartYardSharedObject]
    
    public init(accessToken: String, sharedObjects: [SmartYardSharedObject]) {
        self.accessToken = accessToken
        self.sharedObjects = sharedObjects
    }

}

extension SmartYardSharedData {
    
    public static func loadSharedData() -> SmartYardSharedData {
        let decoder = PropertyListDecoder()
        
        do {
            let data = try Data(contentsOf: sharedDataFileURL)
            return try decoder.decode(SmartYardSharedData.self, from: data)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    public static func saveSharedData(data: SmartYardSharedData) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        do {
            let data = try encoder.encode(data)
            try data.write(to: sharedDataFileURL)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    public static func clearSharedData() {
        let emptyData = SmartYardSharedData(accessToken: "", sharedObjects: [])
        saveSharedData(data: emptyData)
    }
    
    static var sharedDataFileURL: URL {
        let appGroupIdentifier = "group.com.madbrains.smartyard.widget"
        
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        else { preconditionFailure("Expected a valid app group container") }
        
        return url.appendingPathComponent("Data.plist")
    }
    
}
