//
//  SmartYardSharedDataUtilities.swift
//  SmartYardSharedDataFramework
//
//  Created by Александр Васильев on 27.10.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

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
    
    public static func sendOpenDoorRequest(
        accessToken: String,
        backendURL: String,
        doorId: Int,
        domophoneId: String,
        completionHandler: ((_ success: Bool) -> Void)? = nil
    ) {
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
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            guard let completionHandler = completionHandler else {
                return
            }
            guard let response = response as? HTTPURLResponse else {
                completionHandler(false)
                return
            }
            completionHandler(response.statusCode == 204)
        }
        .resume()
    }
    
    static var sharedDataFileURL: URL {
        #if DEBUG
        let appGroupIdentifier = "group.com.sesameware.smartyard.oem.widget"
        #elseif RELEASE
        let appGroupIdentifier = "group.com.sesameware.smartyard.oem.widget"
        #endif
        
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        else {
            preconditionFailure("Expected a valid app group container")
        }
        
        return url.appendingPathComponent("Data.plist")
    }
    
}
