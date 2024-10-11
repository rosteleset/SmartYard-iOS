//
//  ApiWrapper+CCTV.swift
//  SmartYard
//
//  Created by admin on 01.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension APIWrapper {
    
    func getAllCCTV(houseId: String?, forceRefresh: Bool = false) -> Single<AllCCTVResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = AllCCTVRequest(accessToken: accessToken, forceRefresh: forceRefresh, houseId: houseId)
        
        return provider.rx
            .request(.allCCTV(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getAllCameras(forceRefresh: Bool = false) -> Single<AllCamerasResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = AllCamerasRequest(accessToken: accessToken, forceRefresh: forceRefresh)
        
        return provider.rx
            .request(.allCameras(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getAllPlaces(forceRefresh: Bool = false) -> Single<AllPlacesResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = AllPlacesRequest(accessToken: accessToken, forceRefresh: forceRefresh)
        
        return provider.rx
            .request(.allPlaces(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }

    func getCamCCTV(camId: Int?, forceRefresh: Bool = false) -> Single<CamCCTVResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = CamCCTVRequest(accessToken: accessToken, forceRefresh: forceRefresh, camId: camId)
        
        return provider.rx
            .request(.camCCTV(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getCityCoordinate(cityName: String?, forceRefresh: Bool = false) -> Single<CityCoordinateResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = CityCoordinateRequest(accessToken: accessToken, forceRefresh: forceRefresh, cityName: cityName)
        
        return provider.rx
            .request(.cityCoordinate(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func recPrepare(id: Int, from: String, to: String) -> Single<Int?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = RecPrepareRequest(accessToken: accessToken, id: id, from: from, to: to)
        
        return provider.rx
            .request(.recPrepare(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func recSize(id: Int, from: String, to: String) -> Single<String?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = RecSizeRequest(accessToken: accessToken, id: id, from: from, to: to)
        
        return provider.rx
            .request(.recSize(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    func camSortCCTV(sort: [Int]) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = CamSortCCTVRequest(accessToken: accessToken, sort: sort)
        
        return provider.rx
            .request(.camSortCCTV(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func recDownload(id: Int) -> Single<RecDownloadResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = RecDownloadRequest(accessToken: accessToken, id: id)
        
        return provider.rx
            .request(.recDownload(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getArchiveRanges(cameraUrl: String, from: Int, token: String) -> Single<[APIArchiveRange]?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        let request = StreamInfoRequest(cameraUrl: cameraUrl, from: from, token: token)
        
        return provider.rx
            .request(.streamInfo(request: request))
            .convertNoConnectionError()
            .map([APIArchiveStreamInfo].self)
            .map { streamInfo in
                streamInfo.first?.ranges ?? []
            }
            .mapToOptional()
    }
    
    func getOverviewCCTV(forceRefresh: Bool = false) -> Single<OverviewCCTVResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = OverviewCCTVRequest(accessToken: accessToken, forceRefresh: forceRefresh)
        
        return provider.rx
            .request(.overviewCCTV(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getYouTubeVideo(cameraId: Int?, forceRefresh: Bool = false) -> Single<YouTubeResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = YouTubeRequest(accessToken: accessToken, forceRefresh: forceRefresh, id: cameraId)
        
        return provider.rx
            .request(.youtube(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
}
