//
//  LogoutWorkflow.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 LanTa. All rights reserved.
//

import RxSwift

final class LogoutWorkflow {
    typealias ResetPushRegistration = () -> Completable

    private let disableAutomaticPushRegistration: () -> Void
    private let deletePushToken: () -> Void
    private let resetPushRegistration: ResetPushRegistration
    private let clearSharedData: () -> Void
    private let clearSession: () -> Void

    init(
        disableAutomaticPushRegistration: @escaping () -> Void,
        deletePushToken: @escaping () -> Void,
        resetPushRegistration: @escaping ResetPushRegistration,
        clearSharedData: @escaping () -> Void,
        clearSession: @escaping () -> Void
    ) {
        self.disableAutomaticPushRegistration = disableAutomaticPushRegistration
        self.deletePushToken = deletePushToken
        self.resetPushRegistration = resetPushRegistration
        self.clearSharedData = clearSharedData
        self.clearSession = clearSession
    }

    func run() -> Completable {
        return Completable.deferred { [self] in
            disableAutomaticPushRegistration()
            deletePushToken()

            return resetPushRegistration()
                .catch { _ in .empty() }
                .andThen(
                    Completable.deferred { [self] in
                        clearSharedData()
                        clearSession()

                        return .empty()
                    }
                )
        }
    }
}
