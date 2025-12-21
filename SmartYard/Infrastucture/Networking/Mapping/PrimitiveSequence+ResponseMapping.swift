//
//  PrimitiveSequence+ResponseMapping.swift
//  SmartYard
//
//  Created by Александр Попов on 21.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxSwift
import Moya

extension PrimitiveSequence where Trait == SingleTrait, Element == Response {

    func mapAsVoidResponse() -> Single<Void> {
        return flatMap { response in
            // MARK: Если вернулся успешный код, то просто возвращаем Void
            if 200...299 ~= response.statusCode {
                return .just(())
            }

            // MARK: Если вернулся не особо успешный код, пытаемся достать информацию об ошибке

            return .error(response.extractBaseAPIResponseError())
        }
    }

    func mapAsDefaultResponse<T: Decodable>() -> Single<T> {
        return flatMap { response in
            // MARK: Если вернулся успешный код - пытаемся замапить реквест
            if 200...299 ~= response.statusCode {
                do {
                    let mappedResponse = try response.map(BaseAPIResponse<T>.self)

                    guard let data = mappedResponse.data else {
                        return .error(NSError.APIWrapperError.noDataError)
                    }
                    return .just(data)
                } catch {
                    return .error(NSError.APIWrapperError.baseResponseMappingError)
                }
            }

            // MARK: Если вернулся не особо успешный код, пытаемся достать информацию об ошибке
            return .error(response.extractBaseAPIResponseError())
        }
    }

    func mapAsSberbankResponse() -> Single<SberbankPayProcessResponseData?> {
        return flatMap { response in
            do {
                let mappedResponse = try response.map(SberbankPayProcessResponseData.self)
                return .just(mappedResponse)
            } catch {
                return .error(NSError.APIWrapperError.baseResponseMappingError)
            }
        }
    }

    func mapAsEmptyDataInitializableResponse<T: Decodable & EmptyDataInitializable>() -> Single<T> {
        return flatMap { response in
            // MARK: Если вернулся код 204 (пустой контент), то просто возвращаем пустой контент
            if response.statusCode == 204 {
                return .just(T())
            }

            // MARK: Если вернулся успешный код - пытаемся замапить реквест
            if 200...299 ~= response.statusCode {
                do {
                    let mappedResponse = try response.map(BaseAPIResponse<T>.self)

                    guard let data = mappedResponse.data else {
                        return .error(NSError.APIWrapperError.noDataError)
                    }
                    return .just(data)
                } catch {
                    return .error(NSError.APIWrapperError.baseResponseMappingError)
                }
            }

            // MARK: Если вернулся не особо успешный код, пытаемся достать информацию об ошибке

            return .error(response.extractBaseAPIResponseError())
        }
    }
}
