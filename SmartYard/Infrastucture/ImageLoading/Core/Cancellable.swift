//
//  Cancellable.swift
//  SmartYard
//
//  Created by Александр Попов on 16.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import Foundation

protocol Cancellable {
    func cancel()
}

final class CancelToken: Cancellable {
    private let lock = NSLock()
    private var _isCancelled = false

    func cancel() {
        lock.lock(); defer { lock.unlock() }
        _isCancelled = true
    }

    var isCancelled: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isCancelled
    }
}
