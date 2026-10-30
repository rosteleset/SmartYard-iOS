// Created by Александр Попов. Copyright © 2026 Sesameware.

import Foundation
import XCTest
import RxSwift

final class LicensePlateAccessTests: XCTestCase {
    private let flatId = 42
    private let number = "A123BC77"
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    func test24HoursIsElapsedTimeAcrossDaylightSaving() throws {
        let start = try XCTUnwrap(LicensePlateValidity.date(from: "2026-03-28T12:00:00+01:00"))
        let validity = LicensePlateValidity.day(startingAt: start)
        XCTAssertEqual(try XCTUnwrap(validity.validTo).timeIntervalSince(start), 86_400)
        XCTAssertTrue(validity.lasts24Hours)
        XCTAssertEqual(LicensePlateValidity.apiString(from: try XCTUnwrap(validity.validTo)), "2026-03-29T11:00:00Z")
    }

    func testDecodesMicrosecondsNullBoundsAndFlexibleWatcherID() throws {
        let data = Data(#"{"plateNumber":"A123BC77","countryCode":"RU","validFrom":null,"validTo":"2026-10-31T10:00:00.123456Z","watcherId":"17"}"#.utf8)
        let plate = try JSONDecoder().decode(APILicensePlate.self, from: data)
        XCTAssertEqual(plate.countryCode, "ru")
        XCTAssertNil(plate.validity.validFrom)
        XCTAssertNotNil(plate.validity.validTo)
        XCTAssertEqual(plate.watcherId, 17)
        let bad = Data(#"{"plateNumber":"A123BC77","validTo":"invalid"}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(APILicensePlate.self, from: bad))
    }

    func testLegacyPayloadOmitsV2FieldsAndUnlimitedV2ExplicitlyClearsBounds() {
        let legacy = AddLicensePlateRequest(accessToken: "test", flatId: flatId, number: number)
        XCTAssertEqual(Set(legacy.requestParameters.keys), ["flatId", "number"])
        let timed = AddLicensePlateRequest(accessToken: "test", flatId: flatId, number: number, countryCode: "ru")
        XCTAssertTrue(timed.requestParameters["validFrom"] is NSNull)
        XCTAssertTrue(timed.requestParameters["validTo"] is NSNull)
        XCTAssertNoThrow(try JSONSerialization.data(withJSONObject: timed.requestParameters))
    }

    func testPeriodPayloadUsesUTCAndRejectsReversedBounds() throws {
        let validity = LicensePlateValidity.day(startingAt: start)
        let request = AddLicensePlateRequest(
            accessToken: "test", flatId: flatId, number: number, countryCode: "ru", validity: validity
        )
        XCTAssertEqual(request.requestParameters["validFrom"] as? String, LicensePlateValidity.apiString(from: start))
        let api = APIWrapper()
        let invalid = AllowedCar(rawNumber: number, validFrom: start, validTo: start.addingTimeInterval(-1))
        XCTAssertThrowsError(try value(api.saveAllowedCar(invalid, trackingEnabled: true, replacing: nil, flatId: flatId)))
        XCTAssertTrue(api.calls.isEmpty)
    }

    func testVersionDefaultsToLegacyAndFormatsValidateWholeNormalizedNumber() {
        XCTAssertEqual(LicensePlateAPIVersion(serverValue: nil), .legacy)
        XCTAssertEqual(LicensePlateAPIVersion(serverValue: "3"), .legacy)
        XCTAssertEqual(LicensePlateAPIVersion(serverValue: "2"), .timed)
        let format = APILicensePlateFormat(countryCode: "ru", regex: "[ABCEHKMOPTXY][0-9]{3}[ABCEHKMOPTXY]{2}[0-9]{2,3}")
        XCTAssertTrue(format.matches("А 123 ВС 77".standardizedCarNumber))
        XCTAssertFalse(format.matches("prefixA123BC77"))
    }

    func testListIgnoresOtherDeviceWatcherAndDeduplicatesJoinedRows() throws {
        let api = APIWrapper()
        api.plates = [try plate(watcherId: 999), try plate(watcherId: 998)]
        var cars = try value(api.getAllowedCars(forFlatId: flatId))
        XCTAssertEqual(cars.count, 1)
        XCTAssertNil(cars.first?.watcherId)
        api.watchers = [watcher(id: 7)]
        cars = try value(api.getAllowedCars(forFlatId: flatId))
        XCTAssertEqual(cars.first?.watcherId, 7)
    }

    func testSameNumberUpdatesPeriodInPlaceAndReusesOwnSubscription() throws {
        let api = APIWrapper()
        api.plates = [try plate()]
        api.watchers = [watcher(id: 7)]
        let car = AllowedCar(rawNumber: number, validFrom: start, validTo: start.addingTimeInterval(86_400))
        let result = try value(api.saveAllowedCar(car, trackingEnabled: true, replacing: AllowedCar(rawNumber: number), flatId: flatId))
        XCTAssertEqual(result.car.watcherId, 7)
        XCTAssertFalse(api.calls.contains("remove"))
        XCTAssertFalse(api.calls.contains("track"))
        XCTAssertTrue(result.issues.isEmpty)
        XCTAssertEqual(api.addedRequest?.validity, car.validity)
    }

    func testFailedAdditionDoesNotRemoveOriginalOrChangeTracking() {
        let api = APIWrapper()
        api.failedCalls = ["add"]
        XCTAssertThrowsError(try value(api.saveAllowedCar(
            AllowedCar(rawNumber: number), trackingEnabled: true,
            replacing: AllowedCar(rawNumber: "B456CC77"), flatId: flatId
        )))
        XCTAssertEqual(api.calls, ["add"])
    }

    func testTrackingFailureReportsSavedPassWithoutRepeatingCreation() throws {
        let api = APIWrapper()
        api.plates = [try plate()]
        api.failedCalls = ["track"]
        let result = try value(api.saveAllowedCar(AllowedCar(rawNumber: number), trackingEnabled: true, replacing: nil, flatId: flatId))
        XCTAssertEqual(result.car.apiNumber, number)
        XCTAssertEqual(result.issues, [.tracking])
        XCTAssertEqual(api.calls.filter { $0 == "add" }.count, 1)
        XCTAssertNil(result.car.watcherId)
    }

    func testDisablingTrackingRemovesAllOwnDuplicatesButKeepsUnrelatedEvents() throws {
        let api = APIWrapper()
        api.plates = [try plate()]
        api.watchers = [watcher(id: 7), watcher(id: 8), watcher(id: 9, flat: 43), watcher(id: 10, eventType: 3)]
        _ = try value(api.saveAllowedCar(AllowedCar(rawNumber: number), trackingEnabled: false, replacing: nil, flatId: flatId))
        XCTAssertEqual(Set(api.watchers.map(\.watcherId)), [9, 10])
        XCTAssertFalse(api.calls.contains("track"))
    }

    func testRenameRemovalFailureKeepsBothAndWarns() throws {
        let api = APIWrapper()
        api.failedCalls = ["remove", "listV2"]
        let old = AllowedCar(rawNumber: "B456CC77", watcherId: 11)
        let result = try value(api.saveAllowedCar(AllowedCar(rawNumber: number), trackingEnabled: false, replacing: old, flatId: flatId))
        XCTAssertEqual(result.issues, [.originalAccess, .refresh])
        XCTAssertFalse(result.removedOriginal)
        XCTAssertEqual(result.updating([old], original: old).count, 2)
        XCTAssertNil(result.car.watcherId)
        XCTAssertEqual(Array(api.calls.prefix(2)), ["add", "remove"])
    }

    func testRefreshFailureKeepsUpdatedPassAndKnownWatcher() throws {
        let api = APIWrapper()
        api.failedCalls = ["listV2"]
        api.watchers = [watcher(id: 7)]
        let old = AllowedCar(rawNumber: number, watcherId: 7)
        let car = AllowedCar(rawNumber: number, validFrom: start, validTo: start.addingTimeInterval(86_400))
        let result = try value(api.saveAllowedCar(car, trackingEnabled: true, replacing: old, flatId: flatId))
        let updated = result.updating([old], original: old)
        XCTAssertEqual(updated.count, 1)
        XCTAssertEqual(updated.first?.validTo, car.validTo)
        XCTAssertEqual(updated.first?.watcherId, 7)
        XCTAssertEqual(result.issues, [.refresh])
    }

    func testLegacyOperatorsUseOriginalEndpointAndNeverTrack() throws {
        let api = APIWrapper()
        api.accessService.lprsVersion = .legacy
        api.legacyPlates = [number]
        _ = try value(api.saveAllowedCar(AllowedCar(rawNumber: number), trackingEnabled: true, replacing: nil, flatId: flatId))
        XCTAssertEqual(api.calls, ["add", "list"])
        XCTAssertNil(api.addedRequest?.countryCode)
    }

    func testForeignRemovalDoesNotSendWrongCountryRequest() {
        let api = APIWrapper()
        XCTAssertThrowsError(try value(api.removeAllowedCar(AllowedCar(rawNumber: "1234AB7", countryCode: "by"), forFlatId: flatId)))
        XCTAssertTrue(api.calls.isEmpty)
    }

    private func watcher(id: Int, flat: Int = 42, eventType: Int = 9) -> APITrackedEvent {
        APITrackedEvent(watcherId: id, flatId: flat, eventType: eventType, eventDetail: number)
    }

    private func plate(watcherId: Int? = nil) throws -> APILicensePlate {
        let object: [String: Any] = ["plateNumber": number, "countryCode": "ru", "watcherId": watcherId as Any? ?? NSNull()]
        return try JSONDecoder().decode(APILicensePlate.self, from: JSONSerialization.data(withJSONObject: object))
    }

    private func value<T>(_ single: Single<T>) throws -> T {
        var result: Result<T, Error>?
        let completed = expectation(description: "API completion")
        let disposable = single.subscribe { event in
            result = event
            completed.fulfill()
        }
        wait(for: [completed], timeout: 2)
        disposable.dispose()
        return try XCTUnwrap(result).get()
    }
}
