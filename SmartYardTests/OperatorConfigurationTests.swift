//
//  OperatorConfigurationTests.swift
//  SmartYardTests
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation
import XCTest

final class OperatorConfigurationTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        try super.setUpWithError()

        suiteName = "OperatorConfigurationTests.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil

        try super.tearDownWithError()
    }

    func testEmptyStorageUsesInjectedAndCurrentFixedDefaults() {
        let configuration = makeConfiguration()

        XCTAssertEqual(configuration.backendURL, "https://fallback.example/mobile")
        XCTAssertEqual(configuration.provider, .init(id: "default", name: "default"))
        XCTAssertTrue(configuration.showPayments)
        XCTAssertEqual(configuration.paymentsUrl, "")
        XCTAssertFalse(configuration.showChat)
        XCTAssertEqual(configuration.chatUrl, "")
        XCTAssertEqual(configuration.supportPhone, "")
        XCTAssertEqual(configuration.chatId, "")
        XCTAssertEqual(configuration.chatDomain, "")
        XCTAssertEqual(configuration.chatToken, "")
        XCTAssertFalse(configuration.showCityCams)
        XCTAssertEqual(configuration.phonePrefix, "999")
        XCTAssertEqual(configuration.phonePattern, "##-##")
        XCTAssertTrue(configuration.guestAccessModeOnOnly)
        XCTAssertEqual(configuration.timeZone, "Europe/Moscow")
        XCTAssertEqual(configuration.cctvView, "list")
        XCTAssertEqual(configuration.entrancesView, "list")
        XCTAssertEqual(configuration.activeTab, "addresses")
        XCTAssertEqual(configuration.issuesVersion, "1")
        XCTAssertFalse(configuration.eventsTrackingEnabled)
        XCTAssertFalse(configuration.showStories)
        XCTAssertNil(configuration.stunUrl)
        XCTAssertNil(configuration.nameValidationPattern)
        XCTAssertNil(configuration.deliveryTabsConfig)
    }

    func testReadsValuesStoredUnderExistingKeys() {
        let namePattern = NameValidationPattern(
            validationNamePattern: "name",
            validationPatronymicPattern: "patronymic",
            validationLastPattern: "last"
        )
        let deliveryConfig = DeliveryTabsConfig(layoutVisible: false, visibleTabs: [.office])

        seedExistingValues()

        let configuration = makeConfiguration()

        XCTAssertEqual(configuration.backendURL, "https://operator.example/mobile")
        XCTAssertEqual(configuration.provider, .init(id: "operator-id", name: "Operator"))
        XCTAssertFalse(configuration.showPayments)
        XCTAssertEqual(configuration.paymentsUrl, "https://pay.example")
        XCTAssertTrue(configuration.showChat)
        XCTAssertEqual(configuration.chatUrl, "https://chat.example")
        XCTAssertEqual(configuration.supportPhone, "88005553535")
        XCTAssertEqual(configuration.chatId, "chat-id")
        XCTAssertEqual(configuration.chatDomain, "chat.example")
        XCTAssertEqual(configuration.chatToken, "chat-token")
        XCTAssertTrue(configuration.showCityCams)
        XCTAssertEqual(configuration.phonePrefix, "7")
        XCTAssertEqual(configuration.phonePattern, "(###) ###-##-##")
        XCTAssertFalse(configuration.guestAccessModeOnOnly)
        XCTAssertEqual(configuration.timeZone, "Asia/Irkutsk")
        XCTAssertEqual(configuration.cctvView, "tree")
        XCTAssertEqual(configuration.entrancesView, "preview")
        XCTAssertEqual(configuration.activeTab, "chat")
        XCTAssertEqual(configuration.issuesVersion, "2")
        XCTAssertTrue(configuration.eventsTrackingEnabled)
        XCTAssertTrue(configuration.showStories)
        XCTAssertEqual(configuration.stunUrl, "stun:stun.example:3478")
        XCTAssertEqual(configuration.nameValidationPattern, namePattern)
        XCTAssertEqual(configuration.deliveryTabsConfig, deliveryConfig)
    }

    func testWritesValuesUsingExistingKeysAndRestoresThem() throws {
        let configuration = makeConfiguration()
        let namePattern = NameValidationPattern(
            validationNamePattern: "name",
            validationPatronymicPattern: nil,
            validationLastPattern: "last"
        )
        let deliveryConfig = DeliveryTabsConfig(layoutVisible: true, visibleTabs: [.courier])

        setNonDefaultValues(
            in: configuration,
            namePattern: namePattern,
            deliveryConfig: deliveryConfig
        )
        assertValuesUseExistingKeys()
        try assertCodableValuesUseExistingFormat()

        let restoredConfiguration = makeConfiguration()
        XCTAssertEqual(restoredConfiguration.provider, configuration.provider)
        XCTAssertEqual(restoredConfiguration.nameValidationPattern, namePattern)
        XCTAssertEqual(restoredConfiguration.deliveryTabsConfig, deliveryConfig)
    }

    func testOptionalValuesCanBeRemovedAndMalformedDataIsIgnored() {
        let configuration = makeConfiguration()
        configuration.stunUrl = "stun:example"
        configuration.nameValidationPattern = .init(
            validationNamePattern: "name",
            validationPatronymicPattern: nil,
            validationLastPattern: nil
        )
        configuration.deliveryTabsConfig = .init(layoutVisible: true, visibleTabs: [.courier])

        configuration.stunUrl = nil
        configuration.nameValidationPattern = nil
        configuration.deliveryTabsConfig = nil

        XCTAssertNil(defaults.object(forKey: "stunUrlKey"))
        XCTAssertNil(defaults.object(forKey: "nameValidationPatternKey"))
        XCTAssertNil(defaults.object(forKey: "deliveryTabsConfigKey"))

        defaults.set(Data("invalid".utf8), forKey: "nameValidationPatternKey")
        defaults.set(Data("invalid".utf8), forKey: "deliveryTabsConfigKey")

        XCTAssertNil(configuration.nameValidationPattern)
        XCTAssertNil(configuration.deliveryTabsConfig)
    }

    func testProviderFieldsFallBackIndependently() {
        defaults.set("operator-id", forKey: "providerId")

        XCTAssertEqual(
            makeConfiguration().provider,
            .init(id: "operator-id", name: "default")
        )

        defaults.removeObject(forKey: "providerId")
        defaults.set("Operator", forKey: "providerNameKey")

        XCTAssertEqual(
            makeConfiguration().provider,
            .init(id: "default", name: "Operator")
        )
    }

    func testUnexpectedStoredTypesPreserveExistingFallbackBehavior() {
        let keys = [
            "chatId",
            "chatDomain",
            "chatToken",
            "phonePrefixKey",
            "phonePatternKey",
            "timeZoneKey",
            "cctvViewKey",
            "entrancesViewKey",
            "activeTabKey",
            "issuesVersionKey"
        ]
        keys.forEach { defaults.set(123, forKey: $0) }

        let configuration = makeConfiguration()

        XCTAssertEqual(configuration.chatId, "")
        XCTAssertEqual(configuration.chatDomain, "")
        XCTAssertEqual(configuration.chatToken, "")
        XCTAssertEqual(configuration.phonePrefix, "999")
        XCTAssertEqual(configuration.phonePattern, "##-##")
        XCTAssertEqual(configuration.timeZone, "Europe/Moscow")
        XCTAssertEqual(configuration.cctvView, "list")
        XCTAssertEqual(configuration.entrancesView, "list")
        XCTAssertEqual(configuration.activeTab, "addresses")
        XCTAssertEqual(configuration.issuesVersion, "1")
    }

    func testPhonePatternParsingAndLengthsPreserveCurrentBehavior() {
        let configuration = makeConfiguration()

        configuration.setPhonePattern(nil)
        configuration.setPhonePattern("not a phone pattern")

        XCTAssertEqual(configuration.phonePrefix, "999")
        XCTAssertEqual(configuration.phonePattern, "##-##")

        configuration.setPhonePattern("+7 (###) ###-##-##")

        XCTAssertEqual(configuration.phonePrefix, "7")
        XCTAssertEqual(configuration.phonePattern, "(###) ###-##-##")
        XCTAssertEqual(configuration.phoneLengthWithoutPrefix, 10)
        XCTAssertEqual(configuration.phoneLengthWithPrefix, 12)

        configuration.setPhonePattern("44 ###")

        XCTAssertEqual(configuration.phonePrefix, "44")
        XCTAssertEqual(configuration.phonePattern, "###")
        XCTAssertEqual(configuration.phoneLengthWithPrefix, 6)
    }
}

private extension OperatorConfigurationTests {
    private func makeConfiguration() -> OperatorConfiguration {
        OperatorConfiguration(
            storage: defaults,
            defaultValues: .init(
                backendURL: "https://fallback.example/mobile",
                phonePrefix: "999",
                phonePattern: "##-##",
                timeZone: "Europe/Moscow",
                cctvView: "list",
                entrancesView: "list",
                activeTab: "addresses"
            )
        )
    }

    private func seedExistingValues() {
        defaults.set("https://operator.example/mobile", forKey: "backendURL")
        defaults.set("operator-id", forKey: "providerId")
        defaults.set("Operator", forKey: "providerNameKey")
        defaults.set(false, forKey: "showPayments")
        defaults.set("https://pay.example", forKey: "paymentsUrl")
        defaults.set(true, forKey: "showChat")
        defaults.set("https://chat.example", forKey: "chatUrl")
        defaults.set("88005553535", forKey: "supportPhoneKey")
        defaults.set("chat-id", forKey: "chatId")
        defaults.set("chat.example", forKey: "chatDomain")
        defaults.set("chat-token", forKey: "chatToken")
        defaults.set(true, forKey: "showCityCams")
        defaults.set("7", forKey: "phonePrefixKey")
        defaults.set("(###) ###-##-##", forKey: "phonePatternKey")
        defaults.set(false, forKey: "guestAccessKey")
        defaults.set("Asia/Irkutsk", forKey: "timeZoneKey")
        defaults.set("tree", forKey: "cctvViewKey")
        defaults.set("preview", forKey: "entrancesViewKey")
        defaults.set("chat", forKey: "activeTabKey")
        defaults.set("2", forKey: "issuesVersionKey")
        defaults.set(true, forKey: "eventsTrackingEnabledKey")
        defaults.set(true, forKey: "showStoriesKey")
        defaults.set("stun:stun.example:3478", forKey: "stunUrlKey")
        let namePatternData = Data(
            """
            {
              "validationNamePattern": "name",
              "validationPatronymicPattern": "patronymic",
              "validationLastPattern": "last"
            }
            """.utf8
        )
        let deliveryConfigData = Data(
            """
            {
              "layoutVisible": false,
              "visibleTabs": ["office"]
            }
            """.utf8
        )
        defaults.set(namePatternData, forKey: "nameValidationPatternKey")
        defaults.set(deliveryConfigData, forKey: "deliveryTabsConfigKey")
    }

    private func setNonDefaultValues(
        in configuration: OperatorConfiguration,
        namePattern: NameValidationPattern,
        deliveryConfig: DeliveryTabsConfig
    ) {
        configuration.backendURL = "https://new.example/mobile"
        configuration.provider = .init(id: "new-id", name: "New operator")
        configuration.showPayments = false
        configuration.paymentsUrl = "https://new-pay.example"
        configuration.showChat = true
        configuration.chatUrl = "https://new-chat.example"
        configuration.supportPhone = "12345"
        configuration.chatId = "new-chat-id"
        configuration.chatDomain = "new-chat.example"
        configuration.chatToken = "new-chat-token"
        configuration.showCityCams = true
        configuration.phonePrefix = "7"
        configuration.phonePattern = "###"
        configuration.guestAccessModeOnOnly = false
        configuration.timeZone = "UTC"
        configuration.cctvView = "tree"
        configuration.entrancesView = "preview"
        configuration.activeTab = "menu"
        configuration.issuesVersion = "3"
        configuration.eventsTrackingEnabled = true
        configuration.showStories = true
        configuration.stunUrl = "stun:example"
        configuration.nameValidationPattern = namePattern
        configuration.deliveryTabsConfig = deliveryConfig
    }

    private func assertValuesUseExistingKeys() {
        XCTAssertEqual(defaults.string(forKey: "backendURL"), "https://new.example/mobile")
        XCTAssertEqual(defaults.string(forKey: "providerId"), "new-id")
        XCTAssertEqual(defaults.string(forKey: "providerNameKey"), "New operator")
        XCTAssertEqual(defaults.object(forKey: "showPayments") as? Bool, false)
        XCTAssertEqual(defaults.string(forKey: "paymentsUrl"), "https://new-pay.example")
        XCTAssertEqual(defaults.object(forKey: "showChat") as? Bool, true)
        XCTAssertEqual(defaults.string(forKey: "chatUrl"), "https://new-chat.example")
        XCTAssertEqual(defaults.string(forKey: "supportPhoneKey"), "12345")
        XCTAssertEqual(defaults.string(forKey: "chatId"), "new-chat-id")
        XCTAssertEqual(defaults.string(forKey: "chatDomain"), "new-chat.example")
        XCTAssertEqual(defaults.string(forKey: "chatToken"), "new-chat-token")
        XCTAssertEqual(defaults.object(forKey: "showCityCams") as? Bool, true)
        XCTAssertEqual(defaults.string(forKey: "phonePrefixKey"), "7")
        XCTAssertEqual(defaults.string(forKey: "phonePatternKey"), "###")
        XCTAssertEqual(defaults.object(forKey: "guestAccessKey") as? Bool, false)
        XCTAssertEqual(defaults.string(forKey: "timeZoneKey"), "UTC")
        XCTAssertEqual(defaults.string(forKey: "cctvViewKey"), "tree")
        XCTAssertEqual(defaults.string(forKey: "entrancesViewKey"), "preview")
        XCTAssertEqual(defaults.string(forKey: "activeTabKey"), "menu")
        XCTAssertEqual(defaults.string(forKey: "issuesVersionKey"), "3")
        XCTAssertEqual(defaults.object(forKey: "eventsTrackingEnabledKey") as? Bool, true)
        XCTAssertEqual(defaults.object(forKey: "showStoriesKey") as? Bool, true)
        XCTAssertEqual(defaults.string(forKey: "stunUrlKey"), "stun:example")
    }

    private func assertCodableValuesUseExistingFormat() throws {
        let namePatternData = try XCTUnwrap(defaults.data(forKey: "nameValidationPatternKey"))
        let namePatternJSON = try XCTUnwrap(
            JSONSerialization.jsonObject(with: namePatternData) as? [String: Any]
        )
        XCTAssertEqual(
            Set(namePatternJSON.keys),
            Set(["validationNamePattern", "validationLastPattern"])
        )
        XCTAssertEqual(namePatternJSON["validationNamePattern"] as? String, "name")
        XCTAssertEqual(namePatternJSON["validationLastPattern"] as? String, "last")

        let deliveryConfigData = try XCTUnwrap(defaults.data(forKey: "deliveryTabsConfigKey"))
        let deliveryConfigJSON = try XCTUnwrap(
            JSONSerialization.jsonObject(with: deliveryConfigData) as? [String: Any]
        )
        XCTAssertEqual(
            Set(deliveryConfigJSON.keys),
            Set(["layoutVisible", "visibleTabs"])
        )
        XCTAssertEqual(deliveryConfigJSON["layoutVisible"] as? Bool, true)
        XCTAssertEqual(deliveryConfigJSON["visibleTabs"] as? [String], ["courier"])
    }
}
