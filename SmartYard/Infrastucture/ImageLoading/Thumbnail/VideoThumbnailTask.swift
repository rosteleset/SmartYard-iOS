//
//  VideoThumbnailTask.swift
//  SmartYard
//
//  Created by Александр Попов on 16.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import Foundation
import AVFoundation

final class VideoThumbnailTask: Cancellable {
    private let lock = NSLock()
    private var cancelled = false

    private var generator: AVAssetImageGenerator?

    func bind(generator: AVAssetImageGenerator) {
        lock.lock(); defer { lock.unlock() }
        self.generator = generator
        if cancelled { generator.cancelAllCGImageGeneration() }
    }

    func cancel() {
        lock.lock()
        cancelled = true
        let gen = generator
        lock.unlock()

        gen?.cancelAllCGImageGeneration()
    }

    var isCancelled: Bool {
        lock.lock(); defer { lock.unlock() }
        return cancelled
    }
}
