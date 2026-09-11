//
//  MessagePushRoutingPolicy.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

enum MessagePushEffect: Equatable {
    case refreshInbox
    case markInboxUnread
    case refreshChat
    case markChatUnread
    case addressAdded
    case paymentCompleted
    case logPaymentSuccess
    case logPaymentFailure
}

enum MessagePushDestination: Equatable {
    case notifications
    case chat
}

struct ForegroundMessagePushDecision: Equatable {
    let shouldPresentSystemNotification: Bool
    let effects: [MessagePushEffect]
}

struct OpenedMessagePushDecision: Equatable {
    let destination: MessagePushDestination
    let effects: [MessagePushEffect]
}

enum MessagePushRoutingPolicy {
    static func foreground(
        action: MessageType,
        isChatVisible: Bool
    ) -> ForegroundMessagePushDecision {
        switch action {
        case .inbox, .videoReady:
            return ForegroundMessagePushDecision(
                shouldPresentSystemNotification: true,
                effects: [.refreshInbox, .markInboxUnread]
            )
        case .chat:
            return ForegroundMessagePushDecision(
                shouldPresentSystemNotification: !isChatVisible,
                effects: [.refreshChat, .markChatUnread]
            )
        case .newAddress:
            return ForegroundMessagePushDecision(
                shouldPresentSystemNotification: true,
                effects: [.addressAdded]
            )
        case .paySuccess:
            return ForegroundMessagePushDecision(
                shouldPresentSystemNotification: true,
                effects: [.paymentCompleted, .logPaymentSuccess]
            )
        case .payError:
            return ForegroundMessagePushDecision(
                shouldPresentSystemNotification: true,
                effects: [.logPaymentFailure]
            )
        }
    }

    static func opened(action: MessageType) -> OpenedMessagePushDecision {
        switch action {
        case .inbox, .videoReady:
            return OpenedMessagePushDecision(
                destination: .notifications,
                effects: [.refreshInbox]
            )
        case .chat:
            return OpenedMessagePushDecision(destination: .chat, effects: [])
        case .newAddress:
            return OpenedMessagePushDecision(
                destination: .notifications,
                effects: [.refreshInbox, .addressAdded]
            )
        case .paySuccess:
            return OpenedMessagePushDecision(
                destination: .notifications,
                effects: [.refreshInbox, .paymentCompleted, .logPaymentSuccess]
            )
        case .payError:
            return OpenedMessagePushDecision(
                destination: .notifications,
                effects: [.refreshInbox, .logPaymentFailure]
            )
        }
    }
}
