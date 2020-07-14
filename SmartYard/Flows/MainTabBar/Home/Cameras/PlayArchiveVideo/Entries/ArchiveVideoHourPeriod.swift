//
//  ArchiveVideoHourPeriod.swift
//  SmartYard
//
//  Created by admin on 03.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct ArchiveVideoHourPeriod: Equatable {
    
    /// Дата по МСК, 00:00
    let baseDate: Date
    
    /// Начало периода (в часах)
    let startHours: Int
    
    /// Конец периода (в часах)
    let endHours: Int
    
    var title: String {
        return String(format: "%02d", startHours) + ".00 - " + String(format: "%02d", endHours) + ".00"
    }
    
    /// Компоненты URL для трехчасового видео
    
    var videoUrlComponents: String? {
        let startOfDay = Calendar.moscowCalendar.startOfDay(for: baseDate)

        let startDate = startOfDay.adding(.hour, value: startHours)
        let endDate = startOfDay.adding(.hour, value: endHours)
        
        let startTimestamp = startDate.unixTimestamp.int
        let duration = endDate.timeIntervalSince(startDate).int
        
        return "/index-\(startTimestamp)-\(duration).m3u8"
    }
    
    // MARK: Сервер жрет время по GMT, поэтому переводим в GMT
    /// Компоненты URL для получения thumbnails
    
    func getThumbnailComponents(thumbnailsCount: Int, actualDuration: TimeInterval) -> [String] {
        guard thumbnailsCount > 0 else {
            return []
        }
        
        let startOfDay = Calendar.moscowCalendar.startOfDay(for: baseDate)
        
        let intervalForOneThumbnail = actualDuration / Double(thumbnailsCount)
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy/MM/dd/HH/mm/ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let startDate = startOfDay.adding(.hour, value: startHours)
        
        return (0 ..< thumbnailsCount).map {
            let date = startDate.addingTimeInterval(Double($0) * intervalForOneThumbnail)
            
            return "/\(dateFormatter.string(from: date))-preview.mp4"
        }
    }
    
}
