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
        
        formatter.timeZone = Calendar.serverCalendar.timeZone
        formatter.locale = Calendar.serverCalendar.locale
        formatter.dateFormat = "HH:mm"
        
        return formatter.string(from: startDate) + " - " + formatter.string(from: endDate)
    }
    
    /// Компоненты URL для видео
    
    var videoUrlComponents: String? {
        let startTimestamp = startDate.unixTimestamp.int
        let duration = endDate.timeIntervalSince(startDate).int
        
        return "\(startTimestamp)-\(duration)"
    }

    /// Массив компонентов URL для всех фрагментов
    var videoUrlComponentsArray: [String] {
        
        return ranges.map { arg0 -> String in
            
            let (startDate, endDate) = arg0
            
            let startTimestamp = startDate.unixTimestamp.int
            let duration = endDate.timeIntervalSince(startDate).int
            
            return "\(startTimestamp)-\(duration)"
        }
    }

    /// Компоненты URL для получения thumbnails
    
    func getThumbnailComponents(thumbnailsCount: Int, actualDuration: TimeInterval) -> [Date] {
        guard thumbnailsCount > 0 else {
            return []
        }
        
        let intervalForOneThumbnail = actualDuration / Double(thumbnailsCount)
        
        return (0 ..< thumbnailsCount).map { startDate.addingTimeInterval(Double($0) * intervalForOneThumbnail) }
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
