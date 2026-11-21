//
//  SelectProviderStore.swift
//  SmartYard
//
//  Created by Александр Попов on 29.09.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Observation
import RxCocoa
import RxRelay
import RxSwift

/// Presentation state only. Provider filtering, selection and navigation stay in the Rx model.
@MainActor
@Observable
final class SelectProviderStore {
    var query = "" {
        didSet {
            guard query != oldValue else { return }
            inputProviderName.accept(query)
        }
    }

    private(set) var providers: [ProviderCellModel] = []
    private(set) var isLoading = false

    var canContinue: Bool {
        providers.contains { $0.state == .checkedActive }
    }

    @ObservationIgnored private let viewModel: SelectProviderViewModel
    @ObservationIgnored private let inputProviderName = BehaviorRelay<String?>(value: "")
    @ObservationIgnored private let selectProviderTapped = PublishRelay<Void>()
    @ObservationIgnored private let itemStateChanged = PublishRelay<Int?>()
    @ObservationIgnored private let disposeBag = DisposeBag()
    @ObservationIgnored private var hasStarted = false

    init(viewModel: SelectProviderViewModel) {
        self.viewModel = viewModel
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        let output = viewModel.transform(
            input: SelectProviderViewModel.Input(
                inputProviderName: inputProviderName.asDriver().distinctUntilChanged(),
                selectProviderTapped: selectProviderTapped.asDriver(onErrorDriveWith: .empty()),
                itemStateChanged: itemStateChanged.asDriver(onErrorDriveWith: .empty())
            )
        )

        // Driver delivers on the main scheduler. Assert the actor boundary without
        // creating asynchronous tasks that could reorder selection or loading events.
        output.providers
            .drive(with: self) { owner, providers in
                MainActor.assumeIsolated {
                    owner.providers = providers
                }
            }
            .disposed(by: disposeBag)

        output.isLoading
            .debounce(.milliseconds(25))
            .drive(with: self) { owner, isLoading in
                MainActor.assumeIsolated {
                    owner.isLoading = isLoading
                }
            }
            .disposed(by: disposeBag)
    }

    func selectProvider(id: String) {
        guard let index = providers.firstIndex(where: { $0.provider.id == id }) else { return }
        itemStateChanged.accept(index)
    }

    func continueToPhoneEntry() {
        guard canContinue, !isLoading else { return }
        selectProviderTapped.accept(())
    }
}
