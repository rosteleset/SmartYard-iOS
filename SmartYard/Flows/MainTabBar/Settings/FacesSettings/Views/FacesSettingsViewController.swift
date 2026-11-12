//
//  FacesSettingsViewController.swift
//  SmartYard
//
//  Created by Александр Попов on 12.11.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

final class FacesSettingsViewController: UIHostingController<FacesSettingsScreen> {
    private let store: FacesSettingsStore

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    init(viewModel: FacesSettingsViewModel) {
        let store = FacesSettingsStore(viewModel: viewModel)
        self.store = store
        super.init(rootView: FacesSettingsScreen(store: store))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .SmartYard.backgroundColor
        store.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsUpdateOfSupportedInterfaceOrientations()
        navigationController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard traitCollection.userInterfaceIdiom == .pad, isMovingFromParent else { return }
        let scene = view.window?.windowScene

        if let transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { context in
                guard !context.isCancelled else { return }
                scene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        } else {
            scene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
    }
}
