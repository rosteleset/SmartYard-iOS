//
//  PlayerControlsOverlayView.swift
//  SmartYard
//
//  Created by Александр Попов on 12.05.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit

final class PlayerControlsOverlayView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        return shouldHandleTouch(in: hitView) ? hitView : nil
    }

    private func shouldHandleTouch(in view: UIView) -> Bool {
        guard view !== self else { return false }

        if view is UIControl || view is UICollectionView || view is UISlider {
            return true
        }

        guard let superview = view.superview else { return false }
        return superview === self ? false : shouldHandleTouch(in: superview)
    }
}
