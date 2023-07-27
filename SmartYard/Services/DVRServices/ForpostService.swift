//
//  ForpostService.swift
//  SmartYard
//
//  Created by Александр Васильев on 26.06.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum ForpostService {
    
    /// Возвращает url на скриншот
    static func getScreenshotURL(_ camera: CameraObject) -> String {
        guard var urlBase = URLComponents(string: camera.url()) else {
            print(camera.url())
            return ""
        }
        
        urlBase.queryItems?.removeAll(where: { item in
            item.name == "Format"
        })
        
        urlBase.queryItems?.append(URLQueryItem(name: "Format", value: "JPG"))
        
        return urlBase.url?.absoluteString ?? ""
    }
    
    /// Возвращает url на скриншот
    static func getScreenshotURL(_ camera: CameraObject, date: Date) -> String {
        let tz = Calendar.serverCalendar.timeZone.secondsFromGMT()
        let parameters = "&TS=\(date.timeIntervalSince1970.int)&TZ=\(tz)"
        
        guard var urlBase = URLComponents(string: camera.url() + parameters) else {
            print(camera.url())
            return ""
        }
        
        urlBase.queryItems?.removeAll(where: { item in
            item.name == "Format"
        })
        
        urlBase.queryItems?.append(URLQueryItem(name: "Format", value: "JPG"))
        
        return urlBase.url?.absoluteString ?? ""
    }
    
    static func generateURL(_ camera: CameraObject,
                            parameters: String = "",
                            _ completion: @escaping ( _ urlString: String ) -> Void
    ) {
        guard var urlBase = URLComponents(string: camera.url() + parameters) else {
            print(camera.url())
            return
        }
        
        guard let queryItems = urlBase.queryItems else {
            print(camera.url())
            return
        }
        
        var postParams: [String: Any] = [:]
        
        queryItems.forEach { postParams[$0.name] = $0.value }
        
        urlBase.query = nil
        
        guard let url = urlBase.url else {
            print(camera.url())
            return
        }
        
        var request = URLRequest(url: url)
        
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        request.httpBody = postParams.percentEncoded()
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  let jsonDict = try? JSONDecoder().decode([String: String].self, from: data),
                  let url = URL(string: camera.url())
                  
            else {
                print(error?.localizedDescription ?? "")
                completion("")
                return
            }
            
            if var baseURL = URLComponents(string: url.deletingAllPathComponents().absoluteURL.absoluteString) {
                baseURL.query = nil
                let streamURL = jsonDict["URL"] ?? "empty"
                completion(streamURL)
                print(streamURL)
            }
            
        }
        .resume()
    }
    
    static func generateURL(
        _ camera: CameraObject,
        startDate: Date,
        endDate: Date,
        speed: Float,
        _ completion: @escaping ( _ urlString: String ) -> Void
    ) {
        let speedStr = speed < 1 ? String(format: "%.2f", speed) : String(format: "%.0f", speed)
        let tz = Calendar.serverCalendar.timeZone.secondsFromGMT()
        let parameters = "&TS=\(startDate.timeIntervalSince1970.int)&TZ=\(tz)&Speed=\(speedStr)"
        generateURL(camera, parameters: parameters, completion)
    }
    
}

extension Dictionary {
    func percentEncoded() -> Data? {
        map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed: CharacterSet = .urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

extension CameraObject {
    func url() -> String {
        self.baseURLString + (self.token.isEmpty ? "" : "&\(self.token)")
    }
}
