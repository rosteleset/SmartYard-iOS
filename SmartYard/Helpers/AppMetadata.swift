//
//  AppMetadata.swift
//  SmartYard
//
//  Created by Александр Попов on 14.03.2026.
//

import Foundation

enum AppMetadata {
    
    private enum InfoKey {
        static let bundleName = "CFBundleName"
        static let buildVersion = "CFBundleVersion"
        static let shortVersion = "CFBundleShortVersionString"
    }
    
    static let bundleIdentifier: String? = Bundle.main.bundleIdentifier
    static let bundleName: String? = Bundle.main.infoDictionary?[InfoKey.bundleName] as? String
    static let buildVersion: String? = Bundle.main.infoDictionary?[InfoKey.buildVersion] as? String
    static let shortVersion: String? = Bundle.main.infoDictionary?[InfoKey.shortVersion] as? String
    
}
