//
//  SessionStore.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 LanTa. All rights reserved.
//

import Foundation

final class SessionStore {
    private enum Key {
        static let accessToken = "accessToken"
        static let clientName = "clientName"
        static let clientPhoneNumber = "clientPhoneNumber"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var accessToken: String? {
        get {
            defaults.string(forKey: Key.accessToken)
        }
        set {
            set(newValue, forKey: Key.accessToken)
        }
    }

    var clientName: APIClientName? {
        get {
            decode(APIClientName.self, forKey: Key.clientName)
        }
        set {
            encode(newValue, forKey: Key.clientName)
        }
    }

    var clientPhoneNumber: String? {
        get {
            defaults.string(forKey: Key.clientPhoneNumber)
        }
        set {
            set(newValue, forKey: Key.clientPhoneNumber)
        }
    }

    var hasValidToken: Bool {
        !(accessToken ?? "").isEmpty
    }

    func authorize(token: String, name: APIClientName?, phone: String) {
        accessToken = token
        clientName = name
        clientPhoneNumber = phone
    }

    func clear() {
        accessToken = nil
        clientName = nil
        clientPhoneNumber = nil
    }

    private func set(_ value: String?, forKey key: String) {
        guard let value else {
            defaults.removeObject(forKey: key)
            return
        }

        defaults.set(value, forKey: key)
    }

    private func encode<T: Encodable>(_ value: T?, forKey key: String) {
        guard let value else {
            defaults.removeObject(forKey: key)
            return
        }

        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(type, from: data)
    }
}
