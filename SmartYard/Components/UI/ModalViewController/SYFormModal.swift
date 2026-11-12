//
//  Created by Александр Попов on 12.11.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import UIKit
import SnapKit

@MainActor
enum SYFormModal {
    static let contentInsets = NSDirectionalEdgeInsets(top: 28, leading: 24, bottom: 24, trailing: 24)
    static let sectionSpacing: CGFloat = 20
    static let titleSize: CGFloat = 28
    static let buttonHeight: CGFloat = 52

    static func configurePresentation(of controller: UIViewController) {
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve
    }

    static func place(_ card: UIView, in view: UIView) {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        let availableArea = UIView()
        view.addSubview(availableArea) { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
        availableArea.addSubview(card) { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().inset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
            make.width.equalToSuperview().offset(-32).priority(750)
            make.width.lessThanOrEqualTo(view.readableContentGuide.snp.width)
            make.top.greaterThanOrEqualToSuperview().inset(12)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }
    }
}
