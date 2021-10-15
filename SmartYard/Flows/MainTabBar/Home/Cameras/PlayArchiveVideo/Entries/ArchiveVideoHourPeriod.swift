//
//  ArchiveVideoHourPeriod.swift
//  SmartYard
//
//  Created by admin on 03.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct ArchiveVideoPreviewPeriod /*: Equatable*/ {
    
    let startDate: Date
    let endDate: Date
    
    /// Массив из доступных отрезков видео на сервере для этого периода
    
    let ranges: [(startDate: Date, endDate: Date)]
    
    var title: String {
        let formatter = DateFormatter()
        
        formatter.timeZone = Calendar.moscowCalendar.timeZone
        formatter.locale = Calendar.moscowCalendar.locale
        formatter.dateFormat = "HH:mm"
        
        return formatter.string(from: startDate) + " - " + formatter.string(from: endDate)
    }
    
    /// Компоненты URL для видео
    
    var videoUrlComponents: String? {
        let startTimestamp = startDate.unixTimestamp.int
        let duration = endDate.timeIntervalSince(startDate).int
        
        return "/index-\(startTimestamp)-\(duration).m3u8"
    }

    /// Компоненты URL для видео для фрагмента с номером
    
    func videoUrlComponents( _ index: Int) -> String? {
        let startTimestamp = ranges[index].startDate.unixTimestamp.int
        let duration = ranges[index].endDate.timeIntervalSince(startDate).int
        
        return "/index-\(startTimestamp)-\(duration).m3u8"
    }
    
    ///Массив компонентов URL для всех фрагментов
    var videoUrlComponentsArray: [String] {
        
        return ranges.map { arg0 -> String in
            
            let (startDate, endDate) = arg0
            
            let startTimestamp = startDate.unixTimestamp.int
            let duration = endDate.timeIntervalSince(startDate).int
            
            return "/index-\(startTimestamp)-\(duration).m3u8"
        }
    }

    // MARK: Сервер жрет время по GMT, поэтому переводим в GMT
    /// Компоненты URL для получения thumbnails
    
    func getThumbnailComponents(thumbnailsCount: Int, actualDuration: TimeInterval) -> [String] {
        guard thumbnailsCount > 0 else {
            return []
        }
        
        let intervalForOneThumbnail = actualDuration / Double(thumbnailsCount)
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy/MM/dd/HH/mm/ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return (0 ..< thumbnailsCount).map {
            let date = startDate.addingTimeInterval(Double($0) * intervalForOneThumbnail)
            
            return "/\(dateFormatter.string(from: date))-preview.mp4"
        }
    }
    
    /// Длительность периода по временным меткам начала и конца без учёта пропусков на сервере
    
    var dirtyDuration: Double {
        
        guard ranges.last != nil,
              ranges.first != nil
               else {
            return 0.0
        }
        return ranges.last!.endDate.timeIntervalSince1970 - ranges.first!.startDate.timeIntervalSince1970
    }

    /// Чистая длительность периода с учётом пропусков на сервере
    
    var cleanDuration: Double {
        return self.ranges.map { $0.endDate.timeIntervalSince1970 - $0.startDate.timeIntervalSince1970 }
            .reduce(0.0, +)
    }

}
