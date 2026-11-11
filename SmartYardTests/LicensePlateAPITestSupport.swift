// Created by Александр Попов. Copyright © 2026 Sesameware.

import Foundation
import RxSwift

struct APITrackedEvent {
    let watcherId: Int
    let flatId: Int
    let eventType: Int
    let eventDetail: String?
    var normalizedEventDetail: String { eventDetail ?? "" }
}

struct TrackEventResponseData {
    let watcherId: Int
}

enum LicensePlateTestTarget {
    case getLicensePlates(request: GetLicensePlatesRequest)
    case getLicensePlatesV2(request: GetLicensePlatesRequest)
    case getLicensePlateFormats(request: GetLicensePlateFormatsRequest)
    case addLicensePlate(request: AddLicensePlateRequest)
    case removeLicensePlate(request: RemoveLicensePlateRequest)
}

final class LicensePlateTestProvider {
    private unowned let api: APIWrapper
    var rx: LicensePlateTestProvider { self }

    init(api: APIWrapper) { self.api = api }

    func request(_ target: LicensePlateTestTarget) -> Single<LicensePlateTestResponse> {
        .deferred { [self] in
            let value: Any
            switch target {
            case .getLicensePlates:
                try api.record("list")
                value = api.legacyPlates
            case .getLicensePlatesV2:
                try api.record("listV2")
                value = api.plates
            case .getLicensePlateFormats:
                try api.record("formats")
                value = [APILicensePlateFormat]()
            case .addLicensePlate(let request):
                try api.record("add")
                api.addedRequest = request
                value = ()
            case .removeLicensePlate:
                try api.record("remove")
                value = ()
            }
            return .just(LicensePlateTestResponse(value: value))
        }
    }
}

struct LicensePlateTestResponse { let value: Any }

enum Logger {
    static func logDebug(_ message: String) { }
}

// SmartYardTests is hostless. Compile the real APIWrapper+LPRS endpoint against
// this deterministic transport; no account, device subscription or backend is touched.
final class APIWrapper {
    final class Access {
        var accessToken: String? = "test"
        var lprsVersion = LicensePlateAPIVersion.timed
        var eventsTrackingEnabled = true
    }

    let accessService = Access()
    let backend: Void = ()
    let internet: Void = ()
    lazy var provider = LicensePlateTestProvider(api: self)
    var calls: [String] = []
    var failedCalls: Set<String> = []
    var plates: [APILicensePlate] = []
    var legacyPlates: [String] = []
    var watchers: [APITrackedEvent] = []
    var addedRequest: AddLicensePlateRequest?

    func record(_ name: String) throws {
        calls.append(name)
        if failedCalls.contains(name) { throw NSError(domain: "Fixture", code: 503) }
    }

    func getTrackedEvents(flatId: Int) -> Single<[APITrackedEvent]?> {
        .deferred { [self] in
            try record("watchers")
            return .just(watchers)
        }
    }

    func trackEvent(flatId: Int, eventType: Int, eventDetail: String, comments: String) -> Single<TrackEventResponseData?> {
        .deferred { [self] in
            try record("track")
            watchers.append(APITrackedEvent(watcherId: 100, flatId: flatId, eventType: eventType, eventDetail: eventDetail))
            return .just(TrackEventResponseData(watcherId: 100))
        }
    }

    func untrackEvent(watcherId: Int) -> Single<Void?> {
        .deferred { [self] in
            try record("untrack:\(watcherId)")
            watchers.removeAll { $0.watcherId == watcherId }
            return .just(())
        }
    }
}

extension PrimitiveSequence where Trait == SingleTrait, Element == LicensePlateTestResponse {
    func convertNoConnectionError() -> Self { self }
    func trackBackend(_ backend: Void, _ internet: Void) -> Self { self }

    func mapAsEmptyDataInitializableResponse<T>() -> Single<T> {
        map { response in
            guard let value = response.value as? T else { throw NSError.APIWrapperError.noDataError }
            return value
        }
    }

    func mapAsVoidResponse() -> Single<Void> { map { _ in () } }
}

extension PrimitiveSequence where Trait == SingleTrait {
    func mapToOptional() -> Single<Element?> { map { Optional($0) } }
}

extension NSError {
    enum APIWrapperError {
        static let accessTokenMissingError = NSError(domain: "Fixture", code: 401)
        static let noDataError = NSError(domain: "Fixture", code: 422)
    }
}
