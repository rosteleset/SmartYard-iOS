//
//  MacroscopService.swift
//  SmartYard
//
//  Created by Александр Васильев on 10.04.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation

enum MacroscopService {
    
    /// Возвращает url на скриншот
    static func getScreenshotURL(_ camera: CameraObject) -> String {
        let resultingString =
            "&withcontenttype=true&mode=realtime" +
            "&resolutionx=480&resolutiony=270&streamtype=mainvideo"

        if var baseURL = URLComponents(string: camera.baseURLString) {
            baseURL.path = "/site"
            baseURL.query = camera.token.isEmpty ? baseURL.query : (baseURL.query ?? "") + "&\(camera.token)"
            baseURL.query = (baseURL.query ?? "") + resultingString
            
            guard let baseURL = baseURL.url else {
                return ""
            }
            
            let url = baseURL.absoluteString
            print(url)
            return url
        }
        return ""
    }
    
    /// Возвращает url на скриншот
    static func getScreenshotURL(_ camera: CameraObject, date: Date) -> String {
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
        
        if var baseURL = URLComponents(string: camera.baseURLString) {
            baseURL.path = "/site"
            baseURL.query = camera.token.isEmpty ? baseURL.query : (baseURL.query ?? "") + "&\(camera.token)"
            baseURL.query = (baseURL.query ?? "") + resultingString
            
            guard let baseURL = baseURL.url else {
                return ""
            }
            
            let url = baseURL.absoluteString
            print(url)
            return url
        }
        
        return ""
    }
    
    static func generateURL(_ camera: CameraObject,
                            parameters: String = "",
                            _ completion: @escaping ( _ urlString: String ) -> Void
    ) {
        let url = camera.baseURLString + (camera.token.isEmpty ? "" : "&\(camera.token)") + parameters
        guard
            let request = URLRequest(urlString: url) else {
                print(url)
                return
        }
        print(camera.baseURLString + parameters)
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  let resourceString = NSString(data: data, encoding: NSUTF8StringEncoding) as? String,
                  let url = URL(string: camera.baseURLString)
                  
            else {
                print(error?.localizedDescription ?? "")
                DispatchQueue.main.async {
                    completion("")
                }
                return
            }
            if var baseURL = URLComponents(string: url.deletingAllPathComponents().absoluteURL.absoluteString) {
                baseURL.query = nil
                guard let baseURL = baseURL.url else {
                    DispatchQueue.main.async {
                        completion("")
                    }
                    return
                }
                
                let streamURL = baseURL.absoluteString + "hls/" + resourceString
                DispatchQueue.main.async {
                    completion(streamURL)
                }
                print(streamURL)
            }
            
        }
        .resume()
    }
    
    static func generateURL(_ camera: CameraObject, startDate: Date, endDate: Date, speed: Float, _ completion: @escaping ( _ urlString: String ) -> Void ) -> Void {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "dd.MM.yyyy'%20'HH:mm:ss"
        
        let starttime = dateFormatter.string(from: startDate)
        
        let speedStr = speed < 1 ? String(format: "%.2f", speed) : String(format: "%.0f", speed)
        let parameters = "&starttime=" + starttime + "&mode=archive&isForward=true&speed=\(speedStr)&sound=off"
        
        generateURL(camera,parameters: parameters, completion)
    }
}

