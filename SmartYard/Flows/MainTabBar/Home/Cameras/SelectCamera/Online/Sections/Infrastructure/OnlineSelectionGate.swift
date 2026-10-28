//
//  OnlineSelectionGate.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

/// Coordinates programmatic scrolling and fullscreen restoration without losing center events.
struct OnlineSelectionGate {
    private var programmaticTargetIndex: Int?
    private var isSuspendedUntilUserInteraction = false

    mutating func waitForProgrammaticScroll(to index: Int) {
        programmaticTargetIndex = index
    }

    mutating func suspendUntilUserInteraction() {
        isSuspendedUntilUserInteraction = true
    }

    mutating func beginUserInteraction() {
        programmaticTargetIndex = nil
        isSuspendedUntilUserInteraction = false
    }

    mutating func shouldForwardCenteredIndex(_ index: Int) -> Bool {
        // Even a suppressed event must acknowledge that programmatic scrolling finished.
        if let targetIndex = programmaticTargetIndex {
            if index == targetIndex { programmaticTargetIndex = nil }
            return false
        }

        return !isSuspendedUntilUserInteraction
    }
}
