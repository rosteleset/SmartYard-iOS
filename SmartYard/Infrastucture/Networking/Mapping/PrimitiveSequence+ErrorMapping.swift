//
//  PrimitiveSequence+ErrorMapping.swift
//  SmartYard
//
//  Created by Александр Попов on 21.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

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
                // Любой успешный сетевой ответ означает: "сеть+бэк живы"
                if 200...399 ~= response.statusCode {
                    backend.reportMaybeAvailable()
                }
            }, onError: { error in
                // Если интернета реально нет — этим должен заниматься InternetMonitor,
                // backend не трогаем.
                guard internet.currentStatus == .online else { return }

                // Вот тут важно: помечаем backend "упал" только на сетевых ошибках
                // (timeout / cannotConnect / connectionLost / DNS и т.д.)
                if Self.isBackendNetworkError(error) {
                    backend.reportUnavailable()
                }
            })
    }

    private static func isBackendNetworkError(_ error: Error) -> Bool {
        // URLError
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut,
                    .cannotFindHost,
                    .cannotConnectToHost,
                    .networkConnectionLost,
                    .dnsLookupFailed,
                    .notConnectedToInternet,   
                    .internationalRoamingOff,
                    .dataNotAllowed,
                    .secureConnectionFailed,
                    .cannotLoadFromNetwork:
                return true
            default:
                return false
            }
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
            return true
        }

        return false
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
