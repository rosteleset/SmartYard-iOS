//
//  SmartYardSharedData.swift
//  SmartYardSharedDataFramework
//
//  Created by Mad Brains on 09.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
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

public enum SmartYardSharedDataUtilities {
    
    public static func loadSharedData() -> SmartYardSharedData? {
        let decoder = PropertyListDecoder()
        
        guard let data = try? Data(contentsOf: sharedDataFileURL) else {
            return nil
        }
         
        return try? decoder.decode(SmartYardSharedData.self, from: data)
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
        let emptyData = SmartYardSharedData(accessToken: "", backendURL: "", sharedObjects: [])
        saveSharedData(data: emptyData)
    }
    
    public static func sendOpenDoorRequest(accessToken: String, backendURL: String, doorId: Int, domophoneId: String) {
        let json: [String: Any] = ["doorId": doorId, "domophoneId": domophoneId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        guard let url = URL(string: backendURL + "/api/address/openDoor") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request)
        task.resume()
    }
    
    static var sharedDataFileURL: URL {
        #if DEBUG
        let appGroupIdentifier = "group.ru.lanta-net.smartyard.widget"
        #elseif RELEASE
        let appGroupIdentifier = "group.ru.lanta-net.smartyard.widget"
        #endif
        
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        else {
            preconditionFailure("Expected a valid app group container")
        }
        
        return url.appendingPathComponent("Data.plist")
    }
    
}

