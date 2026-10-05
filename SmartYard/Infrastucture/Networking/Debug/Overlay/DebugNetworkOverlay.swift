//
//  DebugNetworkOverlay.swift
//  SmartYard
//
//  Created by Александр Попов on 18.12.2025.
//  Copyright © 2025 Sesameware. All rights reserved.
//

import UIKit

final class DebugNetworkOverlay {
    private let controller: DebugNetworkController
    private var window: UIWindow?

    init(controller: DebugNetworkController) {
        self.controller = controller
    }

    func toggle(in windowScene: UIWindowScene) {
        window == nil ? show(in: windowScene) : hide()
    }

    private func show(in windowScene: UIWindowScene) {
        let window = PassthroughWindow(windowScene: windowScene)
        window.windowLevel = .statusBar + 1
        window.rootViewController = DebugNetworkPanelViewController(controller: controller)
        window.isHidden = false
        self.window = window
    }

    func hide() {
        window?.isHidden = true
        window = nil
    }
}

final class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)

        // Если тап по пустому месту окна — пропускаем
        if view === rootViewController?.view {
            return nil
        }

        return view
    }
}
