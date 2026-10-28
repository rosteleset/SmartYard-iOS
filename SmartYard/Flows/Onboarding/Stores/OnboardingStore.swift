//
//  OnboardingStore.swift
//  SmartYard
//
//  Created by Александр Попов on 27.10.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Observation

/// Page state and user actions; the hosting adapter supplies the existing Rx inputs.
@MainActor
@Observable
final class OnboardingStore {
    private(set) var selectedPage: Int
    let pageCount: Int

    @ObservationIgnored private let onSkip: () -> Void
    @ObservationIgnored private let onStart: () -> Void

    var isLastPage: Bool { selectedPage == pageCount - 1 }

    init(
        pageCount: Int,
        initialPage: Int = 0,
        onSkip: @escaping () -> Void,
        onStart: @escaping () -> Void
    ) {
        precondition(pageCount > 0)
        self.pageCount = pageCount
        selectedPage = min(max(initialPage, 0), pageCount - 1)
        self.onSkip = onSkip
        self.onStart = onStart
    }

    func selectPage(_ index: Int) {
        selectedPage = min(max(index, 0), pageCount - 1)
    }

    func advance() {
        guard !isLastPage else { return }
        selectedPage += 1
    }

    func skip() {
        guard !isLastPage else { return }
        onSkip()
    }

    func start() {
        guard isLastPage else { return }
        onStart()
    }
}
