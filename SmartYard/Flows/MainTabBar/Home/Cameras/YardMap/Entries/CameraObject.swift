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
    
    private var liveURL: String {
        switch self.serverType {
        case .nimble:
            return "\(baseURLString)/playlist.m3u8?wmsAuthSign=\(token)"
        case  .macroscop:
            return "empty"
        default:
            return "\(baseURLString)/index.m3u8?token=\(token)"
        }
    }
    
    var previewMP4URL: String {
        switch self.serverType {
        case .nimble:
            return "\(baseURLString)/dvr_thumbnail.mp4?wmsAuthSign=\(token)"
        case .macroscop:
            let resultingString =
                "&withcontenttype=true&mode=realtime" +
                "&resolutionx=480&resolutiony=270&streamtype=mainvideo"
            
            if var baseURL = URLComponents(string: baseURLString) {
                baseURL.path = "/site"
                baseURL.query = token.isEmpty ? baseURL.query : (baseURL.query ?? "") + "&\(token)"
                baseURL.query = (baseURL.query ?? "") + resultingString
                
                guard let baseURL = baseURL.url else {
                    return ""
                }
                
                let url = baseURL.absoluteString
                print(url)
                return url
            }
            
            return ""
        default:
            return "\(baseURLString)/preview.mp4?token=\(token)"
        }
    }
    
    var seekable: Bool {
        switch self.serverType {
        case .macroscop:
            return false
        default:
            return true
        }
    }
    
    func previewMP4URL(_ date: Date) -> String {
        switch self.serverType {
        case .nimble:
            let resultingString = baseURLString +
            "/dvr_thumbnail_\(date.unixTimestamp.int).mp4" +
                "?wmsAuthSign=\(token)"
            print(resultingString)
            return resultingString
        case .macroscop:
            /* http://demo.macroscop.com/site?login=root&channelid=2016897c-8be5-4a80-b1a3-7f79a9ec729c
             &withcontenttype=true&mode=archive&starttime=29.03.2016%2002:20:01&resolutionx=500
             &resolutiony=500&streamtype=mainvideo
            */
        
            let dateFormatter = DateFormatter()
            
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
            
            let resultingString =
                "&withcontenttype=true&mode=archive&starttime=" +
                dateFormatter.string(from: date) +
                "&resolutionx=480&resolutiony=270&streamtype=mainvideo"
            
            if var baseURL = URLComponents(string: baseURLString) {
                baseURL.path = "/site"
                baseURL.query = token.isEmpty ? baseURL.query : (baseURL.query ?? "") + "&\(token)"
                baseURL.query = (baseURL.query ?? "") + resultingString
                
                guard let baseURL = baseURL.url else {
                    return ""
                }
                
                let url = baseURL.absoluteString
                print(url)
                return url
            }
            
            return ""
            
        default:
            let dateFormatter = DateFormatter()
            
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            dateFormatter.dateFormat = "yyyy/MM/dd/HH/mm/ss"
            
            let resultingString = baseURLString +
                "/" +
                dateFormatter.string(from: date) +
                "-preview.mp4" +
                "?token=\(token)"
            return resultingString
        }
    }
    
    func updateURLAndExec(parameters: String = "", _ task: @escaping (_ urlString: String ) -> Void ) {
        // Update live url if needed
        if serverType == .macroscop {
            let url = baseURLString + (token.isEmpty ? "" : "&\(token)") + parameters
            guard
                //let parameters = parameters.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                let request = URLRequest(urlString: url) else {
                    print(url)
                    return
            }
            print(baseURLString + parameters)
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data,
                      let resourceString = NSString(data: data, encoding: NSUTF8StringEncoding) as? String,
                      let url = URL(string: baseURLString)
                      
                else {
                    print(error?.localizedDescription)
                    task("")
                    return
                }
                if var baseURL = URLComponents(string: url.deletingAllPathComponents().absoluteURL.absoluteString) {
                    baseURL.query = nil
                    guard let baseURL = baseURL.url else {
                        task("")
                        return
                    }
                    
                    let streamURL = baseURL.absoluteString + "hls/" + resourceString
                    task(streamURL)
                    print(streamURL)
                }
                
            }
            .resume()
            
        } else {
            print(liveURL)
            task(liveURL)
        }
    }
    
    func getArchiveVideo(startDate: Date, endDate: Date, speed: Float, _ task: @escaping (_ urlString: String? ) -> Void ) {
        if serverType == .macroscop {
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            dateFormatter.dateFormat = "dd.MM.yyyy'%20'HH:mm:ss"
            
            let starttime = dateFormatter.string(from: startDate)
            
            let speedStr = speed < 1 ? String(format: "%.2f", speed) : String(format: "%.0f", speed)
            let parameters = "&starttime=" + starttime + "&mode=archive&isForward=true&speed=\(speedStr)&sound=off"
            
            updateURLAndExec(parameters: parameters, task)
            
        } else {
            let urlString = archiveURL(startDate: startDate, endDate: endDate)
            print(urlString)
            task(urlString)
        }
    }
    
    func dataModelForArchive(period: ArchiveVideoPreviewPeriod) -> Driver<([URL], VideoThumbnailConfiguration)?> {
        guard let fallbackUrl = URL(string: previewMP4URL) else {
            return .just(nil)
        }
        
        let thumbnailConfig = VideoThumbnailConfiguration(
            camera: self,
            period: period,
            fallbackUrl: fallbackUrl
        )
        switch self.serverType {
        case .macroscop:
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
    
    private func archiveURL(startDate: Date, endDate: Date) -> String {
        let startTimestamp = startDate.unixTimestamp.int
        let duration = endDate.timeIntervalSince(startDate).int
        
        let urlComponents = "\(startTimestamp)-\(duration)"
        switch self.serverType {
        case .nimble:
            return "\(baseURLString)/playlist_dvr_range-\(urlComponents).m3u8?wmsAuthSign=\(token)"
        default:
            return "\(baseURLString)/index-\(urlComponents).m3u8?token=\(token)"
        }
    }
    
    init(
        id: Int,
        position: CLLocationCoordinate2D,
        cameraNumber: Int,
        name: String,
        video: String,
        token: String,
        serverType: DVRServerType? = nil) {
            self.id = id
            self.position = position
            self.cameraNumber = cameraNumber
            self.name = name
            self.baseURLString = video
            self.token = token
            self.serverType = serverType ?? .flussonic
    }
    
    init(
        id: Int,
        url: String,
        token: String,
        serverType: DVRServerType? = nil
    ) {
        self.id = id
        self.position = CLLocationCoordinate2D()
        self.cameraNumber = 0
        self.name = ""
        self.baseURLString = url
        self.token = token
        self.serverType = serverType ?? .flussonic
    }
}
