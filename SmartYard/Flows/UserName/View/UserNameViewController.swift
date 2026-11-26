//
//  UserNameViewController.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import SwiftUI

final class UserNameViewController: UIHostingController<UserNameScreen> {
    private let store: UserNameStore

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    init(viewModel: UserNameViewModel, preloadedName: APIClientName?) {
        let store = UserNameStore(viewModel: viewModel, preloadedName: preloadedName)
        self.store = store
        super.init(rootView: UserNameScreen(store: store))
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
        store.willDisappear()
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
