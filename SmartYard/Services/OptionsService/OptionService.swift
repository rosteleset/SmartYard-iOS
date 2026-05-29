//
//  OptionService.swift
//  SmartYard
//
//  Created by Александр Попов on 21.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa

final class OptionsService: OptionsServicing, HasDisposeBag {

    // MARK: - Public
    var optionsUpdated: Observable<Void> { optionsUpdatedRelay.asObservable() }
    private(set) var didLoadOnce = false

    // MARK: - Private
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let networkStateProvider: NetworkStateProviding

    private let optionsUpdatedRelay = PublishRelay<Void>()

    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var needsRefresh = true
    private var lastLoadedAt: Date?

    // Настрой по желанию
    private let ttl: TimeInterval = 6 * 60 * 60 // 6 часов

    init(
        apiWrapper: APIWrapper,
        accessService: AccessService,
        networkStateProvider: NetworkStateProviding
    ) {
        self.apiWrapper = apiWrapper
        self.accessService = accessService
        self.networkStateProvider = networkStateProvider

        bindNetwork()
    }

    func loadIfNeeded(reason: OptionsLoadReason) {
        guard networkStateProvider.currentState == .online else {
            // сеть нет — просто отметим что нужно обновиться
            needsRefresh = true
            return
        }

        guard accessService.hasValidToken else {
            Logger.logDebug("skip load – no valid token")
            needsRefresh = true
            return
        }

        guard !isLoadingRelay.value else { return }

        if shouldReload(reason: reason) {
            load(reason: reason)
        }
    }

    func forceReload(reason: OptionsLoadReason) {
        needsRefresh = true
        loadIfNeeded(reason: reason)
    }

    // MARK: - Private

    private func bindNetwork() {
        networkStateProvider.state
            .distinctUntilChanged()
            .filter { $0 == .online }
            .subscribe(onNext: { [weak self] _ in
                self?.loadIfNeeded(reason: .becameOnline)
            })
            .disposed(by: disposeBag)
    }

    private func shouldReload(reason: OptionsLoadReason) -> Bool {
        // 1) никогда не грузили
        if !didLoadOnce { return true }

        // 2) кто-то пометил как устаревшее (backend сменился / provider сменился / manual)
        if needsRefresh { return true }

        // 3) TTL
        if let lastLoadedAt, Date().timeIntervalSince(lastLoadedAt) > ttl {
            return true
        }

        // 4) холодный старт — можно НЕ грузить, если уже актуально (оставим false)
        switch reason {
        case .coldStart:
            return false
        default:
            return false
        }
    }

    private func load(reason: OptionsLoadReason) {
        isLoadingRelay.accept(true)

        apiWrapper.getOptions()
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .catchAndReturn(nil)
            .subscribe(
                onSuccess: { [weak self] response in
                    guard let self else { return }
                    self.isLoadingRelay.accept(false)

                    guard let response else {
                        self.needsRefresh = true
                        return
                    }

                    self.apply(response)
                    self.didLoadOnce = true
                    self.needsRefresh = false
                    self.lastLoadedAt = Date()
                    self.optionsUpdatedRelay.accept(())
                },
                onFailure: { [weak self] _ in
                    self?.isLoadingRelay.accept(false)
                    self?.needsRefresh = true
                }
            )
            .disposed(by: disposeBag)
    }

    private func apply(_ response: GetOptionsResponseData) {
        if let payments = response.payments { accessService.showPayments = payments; accessService.paymentsUrl = "" }
        if let paymentsUrl = response.paymentsUrl { accessService.paymentsUrl = paymentsUrl }
        if let chatUrl = response.chatUrl { accessService.chatUrl = chatUrl }
        if let supportPhone = response.supportPhone { accessService.supportPhone = supportPhone }
        if let chat = response.chat { accessService.showChat = chat }
        if let chatOptions = response.chatOptions {
            accessService.chatId = chatOptions.id
            accessService.chatDomain = chatOptions.domain
            accessService.chatToken = chatOptions.token
        }
        if let cityCams = response.cityCams { accessService.showCityCams = cityCams }
        if let eventsTracking = response.eventsTracking { accessService.eventsTrackingEnabled = eventsTracking }
        if let stories = response.stories { accessService.showStories = stories }
        if let timeZone = response.timeZone { accessService.timeZone = timeZone }
        if let deliveryTabsConfig = response.deliveryTabsConfig { accessService.deliveryTabsConfig = deliveryTabsConfig }

        accessService.guestAccessModeOnOnly = response.guestAccessOnOnly
        accessService.issuesVersion = response.issuesVersion ?? "1"
        accessService.cctvView = response.cctvView.rawValue
        accessService.entrancesView = response.entrancesView.rawValue

        switch accessService.cctvView {
        case "list": accessService.showList = true
        case "tree": accessService.showList = false
        default: break
        }

        if let validationPattern = response.validationPattern {
            accessService.nameValidationPattern = validationPattern
        }

        accessService.activeTab = response.activeTab.rawValue

        accessService.optionsUpdated.accept(())
    }
}
