//
//  PlayerAudioAvailabilityObserver.swift
//  SmartYard
//
//  Created by Александр Попов on 25.09.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import AVFoundation

/// Observes the tracks of a playing item, including HLS media with no asset-level tracks.
/// Create and release the observer on the main queue. Updates are delivered on the main queue.
final class PlayerAudioAvailabilityObserver {
    enum Availability {
        case unknown
        case available
        case unavailable

        func hasAudio(fallback: Bool) -> Bool {
            switch self {
            case .unknown: return fallback
            case .available: return true
            case .unavailable: return false
            }
        }
    }

    private let item: AVPlayerItem
    private let onChange: (Availability) -> Void
    private var observations: [NSKeyValueObservation] = []
    private var lastAvailability: Availability?

    init(item: AVPlayerItem, onChange: @escaping (Availability) -> Void) {
        self.item = item
        self.onChange = onChange
        observations = [
            item.observe(\.status, options: [.initial, .new]) { [weak self] _, _ in
                self?.scheduleUpdate()
            },
            item.observe(\.tracks, options: [.initial, .new]) { [weak self] _, _ in
                self?.scheduleUpdate()
            }
        ]
    }

    private func scheduleUpdate() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let availability = self.audioAvailability()
            guard availability != self.lastAvailability else { return }
            self.lastAvailability = availability
            self.onChange(availability)
        }
    }

    private func audioAvailability() -> Availability {
        // An empty list while loading is not evidence of a silent recording.
        guard item.status == .readyToPlay, !item.tracks.isEmpty else { return .unknown }

        // AVAsset.tracks can remain empty for HLS even while the item plays audio.
        let mediaTypes = item.tracks.map { $0.assetTrack?.mediaType }
        if mediaTypes.contains(.audio) { return .available }

        // If AVFoundation cannot identify any track, preserve the server fallback.
        return mediaTypes.contains(nil) ? .unknown : .unavailable
    }
}
