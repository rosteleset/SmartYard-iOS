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
                title: L10n.Support.Callback.requestButton,
                style: .default,
                handler: { _ in onAction(.requestCallback) }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: L10n.Support.Call.phoneAction,
                style: .default,
                handler: { _ in onAction(.phoneCall) }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: L10n.Common.cancel,
                style: .cancel
            )
        )

        viewController.present(alert, animated: true)
    }
}
