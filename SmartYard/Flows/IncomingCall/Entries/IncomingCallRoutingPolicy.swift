//
//  IncomingCallRoutingPolicy.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

enum IncomingCallAdmissionDecision: Equatable {
    case enqueue
    case rejectAlreadyHandling
    case rejectIgnored
}

enum IncomingCallPresentationDecision: Equatable {
    case immediately
    case afterCallKitAnswer
}

enum IncomingCallQuickAction: Equatable {
    case none
    case openDoor
    case ignore
}

enum IncomingCallRoutingPolicy {
    static func admission(
        hasEnqueuedCall: Bool,
        isIgnored: Bool
    ) -> IncomingCallAdmissionDecision {
        if hasEnqueuedCall {
            return .rejectAlreadyHandling
        }

        return isIgnored ? .rejectIgnored : .enqueue
    }

    static func presentation(useCallKit: Bool) -> IncomingCallPresentationDecision {
        useCallKit ? .afterCallKitAnswer : .immediately
    }

    static func quickAction(identifier: String) -> IncomingCallQuickAction {
        switch identifier {
        case "OPEN_ACTION":
            return .openDoor
        case "IGNORE_ACTION":
            return .ignore
        default:
            return .none
        }
    }
}
