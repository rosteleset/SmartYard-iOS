//
//  DebugNetworkOverlay.swift
//  SmartYard
//
//  Created by Александр Попов on 18.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit

final class DebugNetworkOverlay {
    private let controller: DebugNetworkController
    private var window: UIWindow?

    init(controller: DebugNetworkController) {
        self.controller = controller
    }

    func toggle() { window == nil ? show() : hide() }

    private func show() {
        let window = PassthroughWindow(frame: UIScreen.main.bounds)
        window.windowLevel = .statusBar + 1
        window.rootViewController = DebugNetworkPanelViewController(controller: controller)
        window.isHidden = false
        self.window = window
    }

    private func hide() {
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
