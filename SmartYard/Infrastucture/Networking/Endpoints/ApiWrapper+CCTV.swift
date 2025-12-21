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
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = AllCCTVRequest(accessToken: accessToken, forceRefresh: forceRefresh, houseId: houseId)
        
        return provider.rx
            .request(.allCCTV(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getAllTreeCCTV(houseId: String?, forceRefresh: Bool = false) -> Single<AllCCTVTreeResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = AllCCTVRequest(accessToken: accessToken, forceRefresh: forceRefresh, houseId: houseId)
        
        return provider.rx
            .request(.allCCTVTree(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func recPrepare(id: Int, from: String, to: String) -> Single<Int?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = RecPrepareRequest(accessToken: accessToken, id: id, from: from, to: to)
        
        return provider.rx
            .request(.recPrepare(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsDefaultResponse()
    }
    
    func recDownload(id: Int) -> Single<RecDownloadResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = RecDownloadRequest(accessToken: accessToken, id: id)
        
        return provider.rx
            .request(.recDownload(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getArchiveRanges(_ camera: CameraObject) -> Single<[APIArchiveRange]?> {
        switch camera.serverType {
        case .nimble, .macroscop, .forpost, .flussonic:
            guard let accessToken = accessService.accessToken else {
                return .error(NSError.APIWrapperError.accessTokenMissingError)
            }
            
            let request = RangesRequest(cameraId: camera.id, accessToken: accessToken)
            
            return provider.rx
                .request(.ranges(request: request))
                .convertNoConnectionError()
                .trackBackend(backend, internet)
                .mapAsDefaultResponse()
                .map { (streamInfo: [APIArchiveStreamInfo]) in
                    streamInfo.first?.ranges ?? []
                }
                .mapToOptional()
        case .trassir:
            return TrassirService.getRanges(camera)
        default:
            let request = StreamInfoRequest(cameraUrl: camera.baseURLString, from: 1525186456, token: camera.token)
            
            return provider.rx
                .request(.streamInfo(request: request))
                .convertNoConnectionError()
                .trackBackend(backend, internet)
                .map([APIArchiveStreamInfo].self)
                .map { streamInfo in
                    streamInfo.first?.ranges ?? []
                }
                .mapToOptional()
        }
    }
    
    func getOverviewCCTV(forceRefresh: Bool = false) -> Single<OverviewCCTVResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = OverviewCCTVRequest(accessToken: accessToken, forceRefresh: forceRefresh)
        
        return provider.rx
            .request(.overviewCCTV(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
    
    func getYouTubeVideo(cameraId: Int?, forceRefresh: Bool = false) -> Single<YouTubeResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = YouTubeRequest(accessToken: accessToken, forceRefresh: forceRefresh, id: cameraId)
        
        return provider.rx
            .request(.youtube(request: request))
            .convertNoConnectionError()
            .trackBackend(backend, internet)
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }
}
