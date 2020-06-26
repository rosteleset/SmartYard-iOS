//
//  ArchiveVideoHourPeriod.swift
//  SmartYard
//
//  Created by admin on 03.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct ArchiveVideoHourPeriod: Equatable {
    
    let baseDate: Date
    let startHours: Int
    let endHours: Int
    
    var title: String {
        return String(format: "%02d", startHours) + ".00 - " + String(format: "%02d", endHours) + ".00"
    }
    
    // MARK: Здесь нам нужно получить таймстамп начала промежутка
    // Время, которое выбирается в пикере - по МСК. Таймстамп же создастся по локальной таймзоне
    // То есть, если мы выбрали 03.00 - 06.00, то по нашему времени это 04.00 - 07.00
    // Поэтому добавляем разницу между локальной таймзоной и МСК, чтобы получить правильный таймстамп
    
    var videoUrlComponents: String? {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
        
        guard let date = Calendar.current.date(from: components) else {
            return nil
        }
        
        let currentOffsetFromGMT = TimeZone.current.secondsFromGMT() / 3600
        let diff = currentOffsetFromGMT - Date.moscowOffsetFromGMT
        
        let startDate = date.adding(.hour, value: startHours + diff)
        let endDate = date.adding(.hour, value: endHours + diff)
        
        let startTimestamp = startDate.unixTimestamp.int
        let duration = endDate.timeIntervalSince(startDate).int
        
        return "/index-\(startTimestamp)-\(duration).m3u8"
    }
    
    // MARK: Здесь нам нужно получить дату скриншота
    // Поскольку используется строковый формат, нам не нужно переводить время из МСК в локальное
    // Но сервер для этого запроса почему-то ожидает время по UTC
    // Поэтому нам нужно отнять разницу между МСК и UTC, чтобы получить правильный скриншот
    
    var videoThumbnailComponents: String? {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
        
        guard let date = Calendar.current.date(from: components) else {
            return nil
        }
        
        let startDate = date.adding(.hour, value: startHours - Date.moscowOffsetFromGMT)
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy/MM/dd/HH/mm/ss"
        
        return "/\(dateFormatter.string(from: startDate))-preview.mp4"
    }
    
}
