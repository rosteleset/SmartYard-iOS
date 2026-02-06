//
//  UIScrollView+Rx.swift
//  SmartYard
//
//  Created by Александр Попов on 24.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIScrollView {

    /// Emit when scroll definitely stopped (drag ended without decel or decel ended).
    var didStopScrolling: Observable<Void> {
        let endDraggingNoDecel = delegate
            .methodInvoked(#selector(UIScrollViewDelegate.scrollViewDidEndDragging(_:willDecelerate:)))
            .compactMap { $0[1] as? Bool }
            .filter { !$0 }
            .map { _ in () }

        let endDecelerating = delegate
            .methodInvoked(#selector(UIScrollViewDelegate.scrollViewDidEndDecelerating(_:)))
            .map { _ in () }

        return Observable.merge(endDraggingNoDecel, endDecelerating)
    }
}
