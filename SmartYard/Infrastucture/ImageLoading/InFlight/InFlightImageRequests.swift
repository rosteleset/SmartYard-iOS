//
//  InFlightImageRequests.swift
//  SmartYard
//
//  Created by Александр Попов on 16.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit

final class InFlightImageRequests {
    static let shared = InFlightImageRequests()

    private struct Entry {
        var observers: [UUID: (UIImage?) -> Void] = [:]
        var cancel: (() -> Void)?
    }

    private let lock = NSLock()
    private var entries: [String: Entry] = [:]

    /// Returns (shouldStart, token)
    func add(key: String, completion: @escaping (UIImage?) -> Void) -> (Bool, UUID) {
        lock.lock(); defer { lock.unlock() }

        let token = UUID()
        if var entry = entries[key] {
            entry.observers[token] = completion
            entries[key] = entry
            return (false, token)
        } else {
            var entry = Entry()
            entry.observers[token] = completion
            entries[key] = entry
            return (true, token)
        }
    }

    func setCancel(key: String, cancel: @escaping () -> Void) {
        lock.lock(); defer { lock.unlock() }
        guard var entry = entries[key] else { return }
        entry.cancel = cancel
        entries[key] = entry
    }

    func remove(key: String, token: UUID) {
        var cancelToCall: (() -> Void)?

        lock.lock()
        guard var entry = entries[key] else { lock.unlock(); return }

        entry.observers[token] = nil

        if entry.observers.isEmpty {
            cancelToCall = entry.cancel
            entries[key] = nil
        } else {
            entries[key] = entry
        }
        lock.unlock()

        cancelToCall?()
    }

    func complete(key: String, image: UIImage?) {
        let observers: [ (UIImage?) -> Void ]

        lock.lock()
        if let entry = entries[key] {
            observers = Array(entry.observers.values)
            entries[key] = nil
        } else {
            observers = []
        }
        lock.unlock()

        DispatchQueue.main.async {
            observers.forEach { $0(image) }
        }
    }
}
