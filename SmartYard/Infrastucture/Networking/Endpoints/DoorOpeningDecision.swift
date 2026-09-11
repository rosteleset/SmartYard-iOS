//
//  DoorOpeningDecision.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

struct DoorOpeningRequestData: Equatable {
    let accessToken: String
    let domophoneId: String
    let doorId: Int?
}

enum DoorOpeningRejection: Equatable {
    case missingAccessToken
    case blocked(reason: String)
}

enum DoorOpeningDecision: Equatable {
    case send(DoorOpeningRequestData)
    case reject(DoorOpeningRejection)

    static func resolve(
        accessToken: String?,
        domophoneId: String,
        doorId: Int?,
        blockReason: String?
    ) -> DoorOpeningDecision {
        guard let accessToken else {
            return .reject(.missingAccessToken)
        }

        if let blockReason {
            return .reject(.blocked(reason: blockReason))
        }

        return .send(
            DoorOpeningRequestData(
                accessToken: accessToken,
                domophoneId: domophoneId,
                doorId: doorId
            )
        )
    }
}
