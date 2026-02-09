//
//  PrimitiveSequence+ErrorMapping.swift
//  SmartYard
//
//  Created by Александр Попов on 21.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import Moya

extension PrimitiveSequence where Trait == SingleTrait, Element == Response {

    func convertNoConnectionError() -> PrimitiveSequence<Trait, Element> {
        `catch` { error in
            let nsError = error as NSError

            guard nsError.domain == "Moya.MoyaError",
                  nsError.code == 6,
                  let afError = nsError.userInfo["NSUnderlyingError"] as? AFError,
                  let underlyingError = afError.underlyingError as NSError?,
                  underlyingError.domain == "NSURLErrorDomain",
                  underlyingError.code == -1009 else {
                throw error
            }

            throw NSError.APIWrapperError.noConnectionError
        }
        .printDebugInfo()
    }

    func trackBackend(_ backend: BackendMonitoring, _ internet: InternetMonitoring) -> Single<Response> {
        self
            .do(onSuccess: { response in
                // Учитываем только успешные ответы именно backend-хоста.
                guard 200...399 ~= response.statusCode,
                      Self.isBackendRequestURL(response.request?.url) else { return }
                backend.reportMaybeAvailable()
            }, onError: { error in
                // Если интернета реально нет — этим должен заниматься InternetMonitor,
                // backend не трогаем.
                guard internet.currentStatus == .online else { return }

                // Помечаем backend "упал" только если это сетевой фейл
                // и запрос был к backend-хосту.
                if Self.isBackendRequestError(error) {
                    backend.reportUnavailable()
                }
            })
    }

    private static func isBackendRequestError(_ error: Error) -> Bool {
        guard let requestURL = extractRequestURL(from: error),
              isBackendRequestURL(requestURL) else {
            return false
        }

        return isBackendNetworkError(error)
    }

    private static func extractRequestURL(from error: Error) -> URL? {
        if let moyaError = error as? MoyaError {
            if let responseURL = moyaError.response?.request?.url {
                return responseURL
            }

            if case .underlying(let underlying, let response) = moyaError {
                if let responseURL = response?.request?.url {
                    return responseURL
                }
                return extractRequestURL(from: underlying)
            }
        }

        if let afError = error as? AFError,
           let underlying = afError.underlyingError {
            return extractRequestURL(from: underlying)
        }

        let ns = error as NSError
        if let failedURL = ns.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            return failedURL
        }

        if let failedURLString = ns.userInfo[NSURLErrorFailingURLStringErrorKey] as? String {
            return URL(string: failedURLString)
        }

        return nil
    }

    private static func isBackendRequestURL(_ url: URL?) -> Bool {
        guard let requestURL = url,
              let backendURL = URL(string: AccessService.shared.backendURL),
              let requestHost = requestURL.host?.lowercased(),
              let backendHost = backendURL.host?.lowercased(),
              requestHost == backendHost else {
            return false
        }

        guard let backendPort = backendURL.port else { return true }
        return requestURL.port == backendPort
    }

    private static func isBackendNetworkError(_ error: Error) -> Bool {
        // URLError
        if let urlError = error as? URLError {
            return isTrackedNetworkErrorCode(urlError.code.rawValue)
        }

        // AFError -> underlying URLError
        if let afError = error as? AFError,
           let underlying = afError.underlyingError as? URLError {
            return isBackendNetworkError(underlying)
        }

        // MoyaError -> underlying
        if let moyaError = error as? MoyaError {
            switch moyaError {
            case .underlying(let underlying, _):
                return isBackendNetworkError(underlying)
            default:
                return false
            }
        }

        // NSError fallback
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain {
            return isTrackedNetworkErrorCode(ns.code)
        }

        return false
    }

    private static func isTrackedNetworkErrorCode(_ code: Int) -> Bool {
        switch code {
        case URLError.timedOut.rawValue,
                URLError.cannotFindHost.rawValue,
                URLError.cannotConnectToHost.rawValue,
                URLError.networkConnectionLost.rawValue,
                URLError.dnsLookupFailed.rawValue,
                URLError.notConnectedToInternet.rawValue,
                URLError.internationalRoamingOff.rawValue,
                URLError.dataNotAllowed.rawValue,
                URLError.secureConnectionFailed.rawValue,
                URLError.cannotLoadFromNetwork.rawValue:
            return true
        default:
            return false
        }
    }

    private func printDebugInfo() -> PrimitiveSequence<Trait, Element> {
        flatMap { response in
            var logLines: [String] = []

            if let request = response.request {
                logLines.append("➡️ Request:")
                logLines.append("URL: \(request.description)")

                if let body = request.httpBody {
                    let bodyString = String(decoding: body, as: UTF8.self)
                    logLines.append("Body: \(bodyString)")
                }

                logLines.append("Headers: \(String(describing: request.headers))")
            }

            logLines.append("⬅️ Response (\(response.statusCode)):")

            if let responseString = try? response.mapString(), !responseString.isEmpty {
                logLines.append(responseString)
            } else {
                logLines.append("<empty>")
            }

            let fullLog = logLines.joined(separator: "\n")
            Logger.logDebug(fullLog)

            return .just(response)
        }
    }
}
