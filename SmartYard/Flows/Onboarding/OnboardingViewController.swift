//
//  OnboardingViewController.swift
//  SmartYard
//
//  Created by Александр Попов on 27.10.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import RxCocoa
import RxRelay
import SwiftUI

/// Temporary UIKit navigation boundary; all onboarding content is native SwiftUI.
final class OnboardingViewController: UIHostingController<OnboardingScreen> {
    private let viewModel: OnboardingViewModel
    private let store: OnboardingStore

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    init(viewModel: OnboardingViewModel, initialPage: Int = 0) {
        let skipTapped = PublishRelay<Void>()
        let letsStartTapped = PublishRelay<Void>()
        let store = OnboardingStore(
            pageCount: OnboardingPage.allCases.count,
            initialPage: initialPage,
            onSkip: { skipTapped.accept(()) },
            onStart: { letsStartTapped.accept(()) }
        )
        self.viewModel = viewModel
        self.store = store
        super.init(rootView: OnboardingScreen(store: store))

        // Bind once per controller lifetime. The existing ViewModel owns its DisposeBag.
        _ = viewModel.transform(input: OnboardingViewModel.Input(
            skipTapped: skipTapped.asDriver(onErrorDriveWith: .empty()),
            letsStartTapped: letsStartTapped.asDriver(onErrorDriveWith: .empty())
        ))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsUpdateOfSupportedInterfaceOrientations()
        navigationController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard traitCollection.userInterfaceIdiom == .pad else { return }
        navigationController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        view.window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .SmartYard.secondBackgroundColor
    }
}
