//
//  MapCamera.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift
import RxCocoa

struct CameraObject: Equatable {
    
    let id: Int
    let position: CLLocationCoordinate2D
    let cameraNumber: Int
    let name: String
    let baseURLString: String
    let token: String
    let serverType: DVRServerType
    let hlsMode: DVRHLSMode
    
    private var liveURL: String {
        switch self.serverType {
        case .nimble:
            return "\(baseURLString)/playlist.m3u8?wmsAuthSign=\(token)"
        case .flussonic:
            return hlsMode == .fmp4 ? "\(baseURLString)/index.fmp4.m3u8?token=\(token)" : "\(baseURLString)/index.m3u8?token=\(token)"
        default:
            return "empty"
        }
    }
    
    var previewURL: String {
        switch self.serverType {
        case .nimble:
            return "\(baseURLString)/dvr_thumbnail.mp4?wmsAuthSign=\(token)"
        case .macroscop:
            return MacroscopService.getScreenshotURL(self)
        case .flussonic:
            return "\(baseURLString)/preview.mp4?token=\(token)"
        case .trassir:
            return TrassirService.getScreenshotURL(self, date: Date())
        case .forpost:
            return ForpostService.getScreenshotURL(self)
        }
    }
    
    /// отвечает за возможность перемотки стандартными средствами плеера. иначе - перезапрос потока.
    var seekable: Bool {
        [.flussonic, .nimble].contains(serverType)
    }
    
    /// отвечает за формат скриншотов
    var screenshotsType: SYImageType {
        let imageType: SYImageType = {
            switch self.serverType {
            case .forpost:
                return .jpegLink
            case .macroscop, .trassir:
                return .jpeg
            default:
                return .mp4
            }
        } ()
        return imageType
    }
    
    func previewURL(_ date: Date) -> String {
        switch self.serverType {
        case .nimble:
            let resultingString = baseURLString +
            "/dvr_thumbnail_\(date.unixTimestamp.int).mp4" +
                "?wmsAuthSign=\(token)"
            print(resultingString)
            return resultingString
        case .macroscop:
            return MacroscopService.getScreenshotURL(self, date: date)
        case .flussonic:
            let dateFormatter = DateFormatter()
            
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            dateFormatter.dateFormat = "yyyy/MM/dd/HH/mm/ss"
            
            let resultingString = baseURLString +
                "/" +
                dateFormatter.string(from: date) +
                "-preview.mp4" +
                "?token=\(token)"
            return resultingString
        case .trassir:
            if TrassirService.getSid(self) != nil {
                return TrassirService.getScreenshotURL(self, date: date)
            } else {
                print("Missing sid")
            }
            return ""
        case .forpost:
            return ForpostService.getScreenshotURL(self, date: date)
        }
    }
    
    func updateURLAndExec(_ task: @escaping ( _ urlString: String ) -> Void ) {
        // Update live url if needed
        switch serverType {
        case .macroscop:
            MacroscopService.generateURL(self, task)
        case .trassir:
            TrassirService.updateSid(self) {
                print(TrassirService.getSid(self) ?? "")
                TrassirService.getToken(self, suffix: "&stream=main") { token in
                    let urlString = TrassirService.generateURL(self, token: token)
                    print(urlString)
                    if !urlString.isEmpty { task(urlString) }
                }
            }
        case .forpost:
            ForpostService.generateURL(self, task)
        default:
            print(liveURL)
            task(liveURL)
        }
    }
    
    func getArchiveVideo(startDate: Date, endDate: Date, speed: Float, _ task: @escaping (_ urlString: String? ) -> Void ) {
        switch serverType {
        case .macroscop:
            MacroscopService.generateURL(self, startDate: startDate, endDate: endDate, speed: speed, task)
        case .trassir:
            TrassirService.updateSid(self) {
                print(TrassirService.getSid(self) ?? "")
                TrassirService.getToken(self, suffix: "&stream=archive_main") { token in
                    TrassirService.playArchive(self, token: token, startDate: startDate, endDate: endDate) { token in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                            let urlString = TrassirService.generateURL(self, token: token)
                            print(urlString)
                            if !urlString.isEmpty { task(urlString) }
                        }
                    }
                }
            }
        case .forpost:
            ForpostService.generateURL(self, startDate: startDate, endDate: endDate, speed: speed, task)
        default:
            let urlString = archiveURL(startDate: startDate, endDate: endDate)
            print(urlString)
            task(urlString)
        }
    }
    
    func dataModelForArchive(period: ArchiveVideoPreviewPeriod) -> Driver<([URL], VideoThumbnailConfiguration)?> {
        guard let fallbackUrl = URL(string: previewURL) else {
            return .just(nil)
        }
        
        let thumbnailConfig = VideoThumbnailConfiguration(
            camera: self,
            period: period,
            fallbackUrl: fallbackUrl
        )
        switch self.serverType {
        case .macroscop, .trassir, .forpost:
            guard let startDate = period.ranges.first?.startDate,
                  let endDate = period.ranges.last?.endDate else {
                return .just(([], thumbnailConfig))
            }
            let observable = Single<String>.create { single in
                getArchiveVideo(startDate: startDate, endDate: endDate, speed: 1.0) { urlString in
                    guard let urlString = urlString else {
                        single(.failure(NSError.APIWrapperError.noDataError))
                        return
                    }
                    single(.success(urlString))
                }

                return Disposables.create { return }
            }
            .map { urlString -> ([URL], VideoThumbnailConfiguration)? in
                guard let url = URL(string: urlString) else {
                    return ([], thumbnailConfig)
                }
                return ([url], thumbnailConfig)
            }
            return observable.asDriver(onErrorJustReturn: nil)
        default:
            let videoUrl = period.ranges.map { range -> URL in
                let url = URL(string: archiveURL(startDate: range.startDate, endDate: range.endDate))
                return url!
            }
            return .just((videoUrl, thumbnailConfig))
        }
    }
    
    func requestRanges(for day: Date, ranges: [APIArchiveRange], completion: @escaping ([APIArchiveRange]) -> Void) {
        
        if serverType == .trassir {
            TrassirService.getRanges(self, date: day) { ranges in
                completion(ranges)
            }
        } else {
            completion(ranges)
        }
    }
    
    private func archiveURL(startDate: Date, endDate: Date) -> String {
        let startTimestamp = startDate.unixTimestamp.int
        let duration = endDate.timeIntervalSince(startDate).int
        
        let urlComponents = "\(startTimestamp)-\(duration)"
        switch self.serverType {
        case .nimble:
            return "\(baseURLString)/playlist_dvr_range-\(urlComponents).m3u8?wmsAuthSign=\(token)"
        default:
            return "\(baseURLString)/index-\(urlComponents).fmp4.m3u8?token=\(token)"
        }
    }
    
    init(
        id: Int,
        position: CLLocationCoordinate2D,
        cameraNumber: Int,
        name: String,
        video: String,
        token: String,
        serverType: DVRServerType? = nil,
        hlsMode: DVRHLSMode? = nil) {
            self.id = id
            self.position = position
            self.cameraNumber = cameraNumber
            self.name = name
            self.baseURLString = video
            self.token = token
            self.serverType = serverType ?? .flussonic
            self.hlsMode = hlsMode ?? .fmp4
    }
    
    init(
        id: Int,
        url: String,
        token: String,
        serverType: DVRServerType? = nil,
        hlsMode: DVRHLSMode? = nil
    ) {
        self.id = id
        self.position = CLLocationCoordinate2D()
        self.cameraNumber = 0
        self.name = ""
        self.baseURLString = url
        self.token = token
        self.serverType = serverType ?? .flussonic
        self.hlsMode = hlsMode ?? .fmp4
    }
}
