//
//  APIPlog.swift
//  SmartYard
//
//  Created by Александр Васильев on 22.03.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

struct APIPlog: Decodable, Equatable, Hashable, EmptyDataInitializable {
    
    let date: Date //дата. Допустимые значения: "Y-m-d H:i:s"
    let uuid: String
    let objectId: Int // идентификатор объекта (домофона)
    let objectType: Int // тип объекта (0 - домофон)
    let objectMechanizma: Int //идентификатор нагрузки (двери). Допустимые значения: "0", "1", "2"
    let mechanizmaDescription: String //описание нагрузки (двери)
    let event: EventType
    let detail: String
    let previewURL: String?
    let previewImage: UIImage?
    
    private enum CodingKeys: String, CodingKey {
        case date
        case uuid
        case objectId
        case objectType
        case objectMechanizma
        case mechanizmaDescription
        case event
        case detail
        case preview
    }
    
    enum EventType: Int {
        case unanswered = 1 //– Неотвеченный вызов в домофон
        case answered = 2//– Отвеченный вызовы в домофон
        case rfid = 3 //– Открытие ключом (+id ключа)
        case app = 4 //– Открытия из приложения  (+id пользователя)
        case face = 5 //– Открытия по распознаванию лица  (+id дескриптора лица)
        case passcode = 6 //– Открытие по коду квартиры
        case call = 7 //– Открытие ворот по звонку (номер звонящего в тексте)
        case plate = 8 //– Открытие ворот по распознаванию номера (номер машины в тексте)
        case unknown = -1
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let dateRawValue = try container.decode(String.self, forKey: .date)
        
        date = try dateRawValue.dateFromAPIString.unwrapped(or: NSError.APIWrapperError.noDataError)
        uuid = try container.decode(String.self, forKey: .uuid)
        objectId = try container.decode(String.self, forKey: .objectId).int ?? -1
        objectType = try container.decode(String.self, forKey: .objectType).int ?? -1
        objectMechanizma = try container.decode(String.self, forKey: .objectMechanizma).int ?? -1
        mechanizmaDescription = try container.decode(String.self, forKey: .mechanizmaDescription)
        event = APIPlog.EventType(rawValue: try container.decode(String.self, forKey: .event).int ?? -1) ?? .unknown
        detail = try container.decode(String.self, forKey: .detail)
        previewURL = try? container.decode(String.self, forKey: .preview)
        
        if let previewURL = previewURL {
            previewImage = UIImage(base64URLString: previewURL)
        } else {
            previewImage = nil
        }
    }
    
    init() {
        date = Date()
        uuid = ""
        objectId = -1
        objectType = -1
        objectMechanizma = -1
        mechanizmaDescription = ""
        event = .unknown
        detail = ""
        previewURL = nil
        previewImage = nil
    }
}
