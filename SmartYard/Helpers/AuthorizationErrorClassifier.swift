//
//  AuthorizationErrorClassifier.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation

enum AuthorizationErrorClassifier {
    static func isUnauthorized(_ error: Error) -> Bool {
        return (error as NSError).code == 401
    }

    static func errorToForward(
        _ error: Error,
        onUnauthorized: () -> Void
    ) -> Error? {
        guard isUnauthorized(error) else {
            return error
        }

        onUnauthorized()

        return nil
    }
}
