//
//  APIService.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Moya
import Alamofire

class APIService {
    
    private let provider: MoyaProvider<APITarget> = {
        let manager = SessionManager()
        manager.retrier = BaseRequestRetrier()
        return MoyaProvider<APITarget>(manager: manager)
    }()
    
    var isReachable: Bool {
        return NetworkReachabilityManager()?.isReachable ?? false
    }
    
    /// Запрос предоставления гостевого доступа на 60 минут
    func performGrantHourGuestAccessRequest(
        _ request: IntercomRequest,
        completion: ((Swift.Result<IntercomResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .grantHourGuestAccess(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    /// Запрос открытия двери
    func performOpenDoorRequest(
        _ request: OpenDoorRequest,
        completion: ((Swift.Result<Void, Error>) -> Void)?
    ) {
        provider.request(
            .openDoor(request: request),
            completion: createEmptyInnerCompletionBlock(from: completion)
        )
    }
    
    /// Запрос на перегенерацию кода открытия
    func performResetCodeRequest(
        _ request: ResetCodeRequest,
        completion: ((Swift.Result<ResetCodeResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .resetCode(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    /// Запрос списка адресов для экрана настроек
    func performSettingsListRequest(
        _ request: GetSettingsListRequest,
        completion: ((Swift.Result<GetSettingsListResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .getSettingsList(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    /// Запрос на получение списка адресов
    func performGetAddressListRequest(
        _ request: GetAddressListRequest,
        completion: ((Swift.Result<GetAddressListResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .getAddressList(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    // User
    
    /// Запрос привязки номера к договору
    func performAddMyPhoneRequest(
        _ request: AddMyPhoneRequest,
        completion: ((Swift.Result<Void, Error>) -> Void)?
    ) {
        provider.request(
            .addMyPhone(request: request),
            completion: createEmptyInnerCompletionBlock(from: completion)
        )
    }
    
    /// Запрос получения СМС-кода
    func performRequestCodeRequest(
        _ request: RequestCodeRequest,
        completion: ((Swift.Result<Void, Error>) -> Void)?
    ) {
        provider.request(
            .requestCode(request: request),
            completion: createEmptyInnerCompletionBlock(from: completion)
        )
    }
    
    /// Запрос отправки токена на сервер
    func performRegisterPushTokenRequest(
        _ request: RegisterPushTokenRequest,
        completion: ((Swift.Result<Void, Error>) -> Void)?
    ) {
        provider.request(
            .registerPushToken(request: request),
            completion: createEmptyInnerCompletionBlock(from: completion)
        )
    }
    
    /// Запрос подтверждения СМС-кода
    func performConfirmCodeRequest(
        _ request: ConfirmCodeRequest,
        completion: ((Swift.Result<ConfirmCodeResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .confirmCode(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    /// Запрос получения списка платежей
    func performGetPaymentsListRequest(
        _ request: GetPaymentsListRequest,
        completion: ((Swift.Result<GetPaymentsListResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .getPaymentsList(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    /// Запрос изменения имени пользователя
    func performSendNameRequest(
        _ request: SendNameRequest,
        completion: ((Swift.Result<Void, Error>) -> Void)?
    ) {
        provider.request(
            .sendName(request: request),
            completion: createEmptyInnerCompletionBlock(from: completion)
        )
    }
    
    /// Запрос получения адреса дома по его id
    func performGetAddressRequest(
        _ request: GetAddressRequest,
        completion: ((Swift.Result<GetAddressResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .getAddress(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    /// Запрос получения геокоординаты по адресу
    func performGetGeoCoderRequest(
        _ request: GeoCoderRequest,
        completion: ((Swift.Result<GeoCoderResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .getGeoCoder(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    /// Запрос получения списка домов
    func performGetHousesRequest(
        _ request: GetHousesRequest,
        completion: ((Swift.Result<GetHousesResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .getHouses(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    /// Запрос получения списка доступных услуг
    func performGetServicesRequest(
        _ request: GetServicesRequest,
        completion: ((Swift.Result<GetServicesResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .getServices(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    /// Запрос получения списка локаций
    func performGetAllLocationsRequest(
        _ request: GetAllLocationsRequest,
        completion: ((Swift.Result<GetAllLocationsResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .getAllLocations(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
    /// Запрос получения списка улиц
    func performGetStreetsRequest(
        _ request: GetStreetsRequest,
        completion: ((Swift.Result<GetStreetsResponseData, Error>) -> Void)?
    ) {
        provider.request(
            .getStreets(request: request),
            completion: createInnerCompletionBlockWithData(from: completion)
        )
    }
    
}

extension APIService {
    
    // MARK: Mapping queries with required Data block
    
    private func createInnerCompletionBlockWithData<T: Decodable>(
        from outerBlock: ((Swift.Result<T, Error>) -> Void)?
    ) -> Completion {
        return { [weak self] result in
            guard let self = self else {
                return
            }
            
            let convertedResult: Swift.Result<T, Error> = {
                switch result {
                case .success(let response): return self.mapResponseWithData(response)
                case .failure(let error): return .failure(error)
                }
            }()
            
            outerBlock?(convertedResult)
        }
    }
    
    private func mapResponseWithData<T: Decodable>(_ response: Response) -> Swift.Result<T, Error> {
        do {
            guard response.statusCode == 200 else {
                let error = NSError(domain: "APIServiceError", code: response.statusCode, userInfo: nil)
                return .failure(error)
            }
            
            let mappedResponse = try response.map(BaseAPIResponse<T>.self)
            
            return .success(mappedResponse.data)
        } catch {
            return .failure(NSError.APIServiceError.mappingError)
        }
    }
    
}

extension APIService {
    
    // MARK: Маппинг запросов, где в респонзе приходит массив каких-то данных
    // Я думал изначально, что там будет просто приходить пустой массив, если нет данных, но приходит код 204 без тела
    // Поскольку дженерики в свифте ну такие себе, пришлось добавить лишний метод
    // Если должен вернуться массив данных, но вернулось 204 - интерпретируем это как пустой массив
    
    private func createInnerCompletionBlockWithData<T: Decodable & EmptyDataInitializable>(
        from outerBlock: ((Swift.Result<T, Error>) -> Void)?
    ) -> Completion {
        return { [weak self] result in
            guard let self = self else {
                return
            }
            
            let convertedResult: Swift.Result<T, Error> = {
                switch result {
                case .success(let response): return self.mapResponseWithData(response)
                case .failure(let error): return .failure(error)
                }
            }()
            
            outerBlock?(convertedResult)
        }
    }
    
    private func mapResponseWithData<T: Decodable & EmptyDataInitializable>(
        _ response: Response
    ) -> Swift.Result<T, Error> {
        do {
            switch response.statusCode {
            case 204:
                return .success(T())
                
            case 200:
                let mappedResponse = try response.map(BaseAPIResponse<T>.self)
                return .success(mappedResponse.data)
                
            default:
                let error = NSError(domain: "APIServiceError", code: response.statusCode, userInfo: nil)
                return .failure(error)
            }
        } catch {
            return .failure(NSError.APIServiceError.mappingError)
        }
    }
    
}

extension APIService {
    
    // MARK: Mapping queries with empty Data block
    
    private func createEmptyInnerCompletionBlock(
        from outerBlock: ((Swift.Result<Void, Error>) -> Void)?
    ) -> Completion {
        return { [weak self] result in
            guard let self = self else {
                return
            }
            
            let convertedResult: Swift.Result<Void, Error> = {
                switch result {
                case .success(let response): return self.mapEmptyResponse(response)
                case .failure(let error): return .failure(error)
                }
            }()
            
            outerBlock?(convertedResult)
        }
    }
    
    private func mapEmptyResponse(_ response: Response) -> Swift.Result<Void, Error> {
        guard response.statusCode == 200 || response.statusCode == 204 else {
            let error = NSError(domain: "APIServiceError", code: response.statusCode, userInfo: nil)
            return .failure(error)
        }
        
        return .success(())
    }
    
}
