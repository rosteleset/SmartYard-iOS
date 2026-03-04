//
//  SupportCallActionsPresenter.swift
//  SmartYard
//
//  Created by Александр Попов on 04.03.2026.
//

import UIKit

enum SupportCallAction {
    case requestCallback
    case phoneCall
}

protocol SupportCallActionsPresenting {
    func present(
        from viewController: UIViewController,
        onAction: @escaping (SupportCallAction) -> Void
    )
}

final class SupportCallActionsPresenter: SupportCallActionsPresenting {
    func present(
        from viewController: UIViewController,
        onAction: @escaping (SupportCallAction) -> Void
    ) {
        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )

        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Request a call back", comment: ""),
                style: .default,
                handler: { _ in onAction(.requestCallback) }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Make a phone call", comment: ""),
                style: .default,
                handler: { _ in onAction(.phoneCall) }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Cancel", comment: ""),
                style: .cancel
            )
        )

        viewController.present(alert, animated: true)
    }
}
