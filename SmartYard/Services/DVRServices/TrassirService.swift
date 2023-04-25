//
//  TrassirService.swift
//  SmartYard
//
//  Created by Александр Васильев on 07.04.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

/// Сервис-обёртка для формирования правильных запросов к API Trassir
// swiftlint:disable:next type_body_length
enum TrassirService {
    
    /// хранилище sid для камер
    private static var sids: [String: String] = [:]
    
    ///  получение sid для камеры
    static func getSid(_ camera: CameraObject) -> String? {
        if  sids.has(key: camera.baseURLString),
            let sid = sids[camera.baseURLString] {
            return sid
        } else {
            return nil
        }
    }
    
    /// обновляет sid для камеры, если его ещё не было получено
    static func updateSid(_ camera: CameraObject, _ task: @escaping () -> Void ) -> Void {
        if  sids.has(key: camera.baseURLString) {
            task()
            return
        }
        guard var urlBase = URLComponents(string: camera.baseURLString) else {
            print(camera.baseURLString)
            return
        }
        urlBase.query = camera.token.isEmpty ? "" : "\(camera.token)"
        urlBase.path = "/login"
        guard let url = urlBase.url else { return }
        let request = URLRequest(url: url)
        print(request.url?.absoluteString ?? "")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: [])
            else {
                print(error?.localizedDescription ?? "")
                task()
                return
            }
            guard  let array = json as? [String: Any],
                   let sid = array["sid"] as? String else { return }
            sids[camera.baseURLString] = sid
            task()
        }
        .resume()
    }
    
    /// получает токен для потока
    static func getToken(_ camera: CameraObject, suffix: String = "&stream=main", _ task: @escaping (String) -> Void ) {
        guard let sid = getSid(camera) else {
            print("hasn't sid")
            return
        }
        guard var urlBase = URLComponents(string: camera.baseURLString) else {
            print(camera.baseURLString)
            return
        }
        urlBase.query?.append("&container=hls&sid=\(sid)")
        if !suffix.isEmpty {
            urlBase.query?.append(suffix)
        }
        urlBase.path = "/get_video"
        guard let url = urlBase.url else {
            print(urlBase)
            return
        }
        let request = URLRequest(url: url)
        print(request.url?.absoluteString ?? "")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: [])
            else {
                print(error?.localizedDescription as Any)
                return
            }
            guard  let array = json as? [String: Any],
                   let success = array["success"] as? Int else { return }
            if success == 1, let token = array["token"] as? String {
                print("get token for \(suffix) = \(token)")
                task(token)
            } else {
                if let error = array["error_code"] as? String {
                    print(error)
                }
            }
            
        }
        .resume()
    }
    
    //    Переместиться на определенное время к ближайшему фрагменту архива:
    //    GET https://server:port/archive_command?command=seek
    //    &timestamp={timestamp}&direction=0&speed={?speed}&sid={sid}&token={token}
    
    /// получает токен для потока
    static func seekTo(_ camera: CameraObject, token: String, startDate: Date, _ task: @escaping (String) -> Void ) {
        guard let sid = getSid(camera) else {
            print("hasn't sid")
            return
        }
        guard var urlBase = URLComponents(string: camera.baseURLString) else {
            print(camera.baseURLString)
                return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = Calendar.moscowCalendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let starttime = dateFormatter.string(from: startDate)
        
        urlBase.query? = "command=seek&timestamp=\(starttime)&direction=0&speed=1&sid=\(sid)&token=\(token)"
        urlBase.path = "/archive_command"
        guard let url = urlBase.url else {
                print(urlBase)
                return
        }
        let request = URLRequest(url: url)
        print(request.url?.absoluteString ?? "")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: [])
            else {
                print(error?.localizedDescription as Any)
                return
            }
            guard  let array = json as? [String: Any] else { return }
            print(array)
            task(token)
        }
        .resume()
    }
    /// подготавливает к воспроизведению фрагмент архива
    static func playArchive(_ camera: CameraObject, token: String, startDate: Date, endDate: Date, _ task: @escaping (String) -> Void ) {
        guard let sid = getSid(camera) else {
            print("hasn't sid")
            return
        }
        guard var urlBase = URLComponents(string: camera.baseURLString) else {
            print(camera.baseURLString)
                return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = Calendar.moscowCalendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let starttime = dateFormatter.string(from: startDate)
        let endtime = dateFormatter.string(from: endDate)
        
        urlBase.query? = "command=play&start=\(starttime)&stop=\(endtime)&speed=1&sid=\(sid)&token=\(token)"
        urlBase.path = "/archive_command"
        guard let url = urlBase.url else {
                print(urlBase)
                return
        }
        let request = URLRequest(url: url)
        print(request.url?.absoluteString ?? "")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: [])
            else {
                print(error?.localizedDescription as Any)
                return
            }
            guard  let array = json as? [String: Any] else { return }
            print(array)
            task(token)
        }
        .resume()
    }
    
    static func seekToLastFrame(_ camera: CameraObject, token: String, _ task: @escaping (String) -> Void ) {
        guard let sid = getSid(camera) else {
            print("hasn't sid")
            return
        }
        guard
            var urlBase = URLComponents(string: camera.baseURLString) else {
            print(camera.baseURLString)
            return
        }
        
        urlBase.query? = "command=frame_last&direction=0&speed=1&sid=\(sid)&token=\(token)"
        urlBase.path = "/archive_command"
        guard let url = urlBase.url else {
            print(urlBase)
            return
        }
        let request = URLRequest(url: url)
        print(request.url?.absoluteString ?? "")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: [])
            else {
                print(error?.localizedDescription as Any)
                return
            }
            guard let array = json as? [String: Any] else { return }
            print(array)
            task(token)
        }
        .resume()
    }
    
    /// сформировать url для получения HLS потока
    static func generateURL(_ camera: CameraObject, token: String) -> String {
        guard var urlBase = URLComponents(string: camera.baseURLString) else { return "" }
        urlBase.path = "/hls/\(token)/master.m3u8"
        urlBase.query = nil
        guard let url = urlBase.url else { return "" }
        let urlString = url.absoluteString
        return urlString
    }
    
    static func getRanges(_ camera: CameraObject) -> Single<[APIArchiveRange]?> {
        let result = PublishSubject<[APIArchiveRange]?>()
        updateSid(camera) {
            getToken(camera, suffix: "&stream=archive_main") { token in
                seekToLastFrame(camera, token: token) { token in
                    var attemptCount = 20
                    func attempt() {
                        getCalendar(camera) { json in
                            guard let array = json as? [[String: Any]],
                                  let calendarObj = array.first(where: { $0["token"] as? String == token }),
                                  let calendar = calendarObj["calendar"] as? [String],
                                  !calendar.isEmpty else {
                                if attemptCount > 0 {
                                    attemptCount -= 1
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        attempt()
                                    }
                                    return
                                } else {
                                    result.onError(NSError.APIWrapperError.noDataError)
                                    result.onCompleted()
                                    return
                                }
                            }
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            dateFormatter.locale = Calendar.moscowCalendar.locale
                            dateFormatter.timeZone = Calendar.moscowCalendar.timeZone
                            let ranges = calendar.map { day -> APIArchiveRange in
                                let from = dateFormatter.date(from: day)?.timeIntervalSince1970.int ?? 0
                                return APIArchiveRange( duration: 3600 * 24 - 1, from: from )
                            }
                            result.onNext(ranges)
                            result.onCompleted()
                        }
                    }
                    attempt()
                }
            }
        }
        return result.asSingle()
    }
    
    static func getCalendar(_ camera: CameraObject, _ completion: @escaping (Any?) -> Void ) {
        guard let sid = getSid(camera) else {
            print("hasn't sid")
            completion(nil)
            return
        }
        guard var urlBase = URLComponents(string: camera.baseURLString) else {
            print(camera.baseURLString)
            completion(nil)
            return
        }
        
        urlBase.query? = "type=calendar&sid=\(sid)"
        urlBase.path = "/archive_status"
        guard let url = urlBase.url else {
            print(urlBase)
            completion(nil)
            return
        }
        let request = URLRequest(url: url)
        print(request.url?.absoluteString ?? "")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: [])
            else {
                print(error?.localizedDescription as Any)
                completion(nil)
                return
            }
            print(json)
            completion(json)
        }
        .resume()
    }
    
    //    Пример запроса шкалы времени архива:
    //
    //    GET https://server:port/archive_status?type=timeline&sid={sid}
    //
    //    sid - Идентификатор сессии
    //
    //    Корректный ответ от сервера:
    //    [
    //        {
    //            "token": {token}, // Токен видео архива
    //            "day_start": "2014-02-24",
    //            "timeline": [
    //                {
    //                    "begin": "43090",
    //                    "end": "43094"
    //                }
    // Время начала и конца фрагмента архива указывается в секундах от начала дня,
    // в диапазоне от 0 до 86400.
    //            ]
    //        }
    //    ]
    static func getTimeline(_ camera: CameraObject, _ completion: @escaping (Any?) -> Void ) {
        guard let sid = getSid(camera) else {
            print("hasn't sid")
            completion(nil)
            return
        }
        guard var urlBase = URLComponents(string: camera.baseURLString) else {
            print(camera.baseURLString)
            completion(nil)
            return
        }
        
        urlBase.query? = "type=timeline&sid=\(sid)"
        urlBase.path = "/archive_status"
        guard let url = urlBase.url else {
            print(urlBase)
            completion(nil)
            return
        }
        let request = URLRequest(url: url)
        print(request.url?.absoluteString ?? "")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: [])
            else {
                print(error?.localizedDescription as Any)
                completion(nil)
                return
            }
            print(json)
            completion(json)
        }
        .resume()
    }
    
    // TODO:
    // Запрос к серверу:
    // GET https://server:port/screenshot/{guid}?timestamp={timestamp}&sid={sid}
    //
    // guid - GUID канала
    // timestamp - Время формата YYYY-MM-DD HH:MM:SS / YYYY-MM-DDTHH:MM:SS / YYYYMMDD-HHMMSS / YYYYMMDDTHHMMSS
    // sid - Идентификатор сессии
    //
    // Корректный ответ от сервера:
    // Скриншот
    
    /// Возвращает url на скриншот
    static func getScreenshotURL(_ camera: CameraObject, date: Date) -> String {
        guard let sid = getSid(camera) else {
            print("hasn't sid")
            return ""
        }
        guard var urlBase = URLComponents(string: camera.baseURLString),
              let guid = urlBase.queryItems?.first(where: { $0.name == "channel" })?.value else {
            print(camera.baseURLString)
            return ""
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Calendar.moscowCalendar.locale
        dateFormatter.timeZone = Calendar.moscowCalendar.timeZone
        
        let timestamp = dateFormatter.string(from: date)
        
        urlBase.query? = "timestamp=\(timestamp)&sid=\(sid)"
        urlBase.path = "/screenshot/\(guid)"
        guard let url = urlBase.url else {
            print(urlBase)
            return ""
        }
        let request = URLRequest(url: url)
        let result = request.url?.absoluteString ?? ""
        print(result)
        return result
    }
    
    static func getRanges(_ camera: CameraObject, date: Date, _ completion: @escaping ([APIArchiveRange]) -> Void) {
        updateSid(camera) {
            getToken(camera, suffix: "&stream=archive_main") { token in
                seekTo(camera, token: token, startDate: date) { token in
                    var attemptCount = 20
                    func attempt() {
                        getTimeline(camera) { json in
                            guard let array = json as? [[String: Any]],
                                  let calendarObj = array.first(where: { $0["token"] as? String == token }),
                                  let timeline = calendarObj["timeline"] as? [[String: String]],
                                  !timeline.isEmpty else {
                                if attemptCount > 0 {
                                    attemptCount -= 1
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        attempt()
                                    }
                                    return
                                } else {
                                    return
                                }
                            }
                            let ranges = timeline.map { day -> APIArchiveRange in
                                let begin = Int(day["begin"] ?? "0") ?? 0
                                let end = Int(day["end"] ?? "0") ?? 0
                                
                                let from = date.adding(.second, value: begin).timeIntervalSince1970.int
                                let duration = date.adding(.second, value: end).timeIntervalSince1970.int - date.timeIntervalSince1970.int
                                
                                return APIArchiveRange( duration: duration, from: from )
                            }
                            completion(ranges)
                            return
                        }
                    }
                    attempt()
                }
            }
        }
    }
}
