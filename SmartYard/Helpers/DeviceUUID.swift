//
//  DeviceUUID.swift
//  SmartYard
//
//  Created by Александр Попов on 08.04.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import Foundation
import Security

final class DeviceUUID {
    
    private init() {}
    
    private static let service: String = Bundle.main.bundleIdentifier ?? "default_service"
    private static let account: String = "device_uuid"
    
    static var value: String {
        if let existing = loadUUID() {
            Logger.logInfo("Loaded UUID from Keychain: \(existing)")
            return existing
        }
        
        let newUUID = UUID().uuidString
        Logger.logInfo("Generated UUID: \(newUUID)")
        let success = saveUUID(newUUID)
        
        if !success {
            Logger.logError("Failed to save UUID in Keychain. Returning generated UUID: \(newUUID)")
        }
        
        return newUUID
    }
    
    private static func loadUUID() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data, let uuid = String(data: data, encoding: .utf8) else {
            Logger.logError("Failed to load UUID from Keychain")
            return nil
        }
        
        return uuid
    }
    
    @discardableResult
    private static func saveUUID(_ uuid: String) -> Bool {
        guard let data = uuid.data(using: .utf8) else {
            Logger.logError("Failed to convert UUID string to Data")
            return false
        }
        
        // На всякий случай — удаляем старую запись
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(deleteQuery as CFDictionary)
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        if status != errSecSuccess {
            Logger.logError("Failed to save UUID in Keychain (status: \(status))")
            return false
        }
        
        return true
    }
    
}
