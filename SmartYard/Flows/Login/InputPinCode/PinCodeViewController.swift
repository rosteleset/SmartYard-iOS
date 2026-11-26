//
//  PinCodeViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import SwiftUI

final class PinCodeViewController: UIHostingController<PinCodeScreen> {
    private let store: PinCodeStore

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    init(viewModel: PinCodeViewModel, isInitial: Bool, useFlashCall: Bool) {
        let store = PinCodeStore(
            viewModel: viewModel,
            isInitial: isInitial,
            useFlashCall: useFlashCall,
            phonePrefix: AccessService.shared.phonePrefix
        )
        self.store = store
        super.init(rootView: PinCodeScreen(store: store, useFlashCall: useFlashCall))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .SmartYard.secondBackgroundColor
        store.start()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        // Lay out the hosted content using the destination window geometry before it becomes visible.
        view.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackAnalyticsScreenOpened()
        setNeedsUpdateOfSupportedInterfaceOrientations()
        navigationController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        store.didAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        store.willDisappear()
        guard traitCollection.userInterfaceIdiom == .pad, isMovingFromParent else { return }

        let scene = view.window?.windowScene
        if let transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { context in
                guard !context.isCancelled, !Self.supportsPadRotation(context.viewController(forKey: .to)) else { return }
                scene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        } else if !Self.supportsPadRotation(navigationController?.viewControllers.last) {
            scene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
    }

    private static func supportsPadRotation(_ destination: UIViewController?) -> Bool {
        destination is InputPhoneNumberViewController || destination is UserNameViewController
    }
}
