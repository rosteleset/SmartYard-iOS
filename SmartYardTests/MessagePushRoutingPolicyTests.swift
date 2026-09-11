//
//  MessagePushRoutingPolicyTests.swift
//  SmartYardTests
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import XCTest

final class MessagePushRoutingPolicyTests: XCTestCase {
    func testForegroundRoutingForEverySupportedMessageAction() {
        let expected: [(MessageType, ForegroundMessagePushDecision)] = [
            (.inbox, .init(
                shouldPresentSystemNotification: true,
                effects: [.refreshInbox, .markInboxUnread]
            )),
            (.videoReady, .init(
                shouldPresentSystemNotification: true,
                effects: [.refreshInbox, .markInboxUnread]
            )),
            (.chat, .init(
                shouldPresentSystemNotification: true,
                effects: [.refreshChat, .markChatUnread]
            )),
            (.newAddress, .init(
                shouldPresentSystemNotification: true,
                effects: [.addressAdded]
            )),
            (.paySuccess, .init(
                shouldPresentSystemNotification: true,
                effects: [.paymentCompleted, .logPaymentSuccess]
            )),
            (.payError, .init(
                shouldPresentSystemNotification: true,
                effects: [.logPaymentFailure]
            ))
        ]

        expected.forEach { action, decision in
            XCTAssertEqual(
                MessagePushRoutingPolicy.foreground(
                    action: action,
                    isChatVisible: false
                ),
                decision,
                "Unexpected foreground route for \(action.rawValue)"
            )
        }
    }

    func testForegroundChatIsHiddenOnlyWhenChatIsAlreadyVisible() {
        let decision = MessagePushRoutingPolicy.foreground(
            action: .chat,
            isChatVisible: true
        )

        XCTAssertEqual(
            decision,
            ForegroundMessagePushDecision(
                shouldPresentSystemNotification: false,
                effects: [.refreshChat, .markChatUnread]
            )
        )
    }

    func testOpenedRoutingForEverySupportedMessageAction() {
        let expected: [(MessageType, OpenedMessagePushDecision)] = [
            (.inbox, .init(destination: .notifications, effects: [.refreshInbox])),
            (.videoReady, .init(destination: .notifications, effects: [.refreshInbox])),
            (.chat, .init(destination: .chat, effects: [])),
            (.newAddress, .init(
                destination: .notifications,
                effects: [.refreshInbox, .addressAdded]
            )),
            (.paySuccess, .init(
                destination: .notifications,
                effects: [.refreshInbox, .paymentCompleted, .logPaymentSuccess]
            )),
            (.payError, .init(
                destination: .notifications,
                effects: [.refreshInbox, .logPaymentFailure]
            ))
        ]

        expected.forEach { action, decision in
            XCTAssertEqual(
                MessagePushRoutingPolicy.opened(action: action),
                decision,
                "Unexpected opened route for \(action.rawValue)"
            )
        }
    }
}
