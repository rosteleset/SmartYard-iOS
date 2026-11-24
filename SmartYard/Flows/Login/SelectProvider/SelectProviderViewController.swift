//
//  SelectProviderViewController.swift
//  SmartYard
//
//  Created by Sesameware on 13.06.2022.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import SwiftUI

/// Keeps the existing coordinator route and hosts the SwiftUI provider screen.
final class SelectProviderViewController: UIHostingController<SelectProviderScreen> {
    private let store: SelectProviderStore

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    init(viewModel: SelectProviderViewModel) {
        let store = SelectProviderStore(viewModel: viewModel)
        self.store = store
        super.init(rootView: SelectProviderScreen(store: store))
        // The search keyboard overlays the panel without moving the footer.
        safeAreaRegions = .container
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
        view.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackAnalyticsScreenOpened()
        setNeedsUpdateOfSupportedInterfaceOrientations()
        navigationController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard traitCollection.userInterfaceIdiom == .pad, isMovingFromParent else { return }
        let scene = view.window?.windowScene

        if let transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { context in
                guard !context.isCancelled, !(context.viewController(forKey: .to) is InputPhoneNumberViewController) else {
                    return
                }
                scene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        } else if !(navigationController?.viewControllers.last is InputPhoneNumberViewController) {
            scene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
    }
}
