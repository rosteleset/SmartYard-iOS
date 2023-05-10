//
//  APIPlog.swift
//  SmartYard
//
//  Created by Александр Васильев on 22.03.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

struct Rectangle: Decodable, Equatable, Hashable {
    let left: Int
    let top: Int
    let width: Int
    let height: Int
    
    private enum CodingKeys: String, CodingKey {
        case left
        case top
        case width
        case height
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        guard let left = try? container.decode(Int.self, forKey: .left),
              let top = try? container.decode(Int.self, forKey: .top),
              let width = try? container.decode(Int.self, forKey: .width),
              let height = try? container.decode(Int.self, forKey: .height) else {
            throw NSError.APIWrapperError.noDataError
        }
        self.left = left
        self.top = top
        self.width = width
        self.height = height
     }
    
    var asCGRect: CGRect {
        return CGRect(x: left, y: top, width: width, height: height)
    }
}

struct DetailX: Decodable, Equatable, Hashable {
    let key: String?
    let face: Rectangle?
    let flags: [String]?
    let phone: String?
    let code: String?
    let faceId: String?
    
    private enum CodingKeys: String, CodingKey {
        case key
        case face
        case flags
        case phone
        case code
        case faceId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        key = try? container.decode(String.self, forKey: .key)
        face = try? container.decode(Rectangle.self, forKey: .face)
        flags = try? container.decode([String].self, forKey: .flags)
        phone = try? container.decode(String.self, forKey: .phone)
        code = try? container.decode(String.self, forKey: .code)
        faceId = try? container.decode(String.self, forKey: .faceId)
     }
    
    // пришлось добавить инициализатор для ручного создания объектов
    init(
        key: String?,
        face: Rectangle?,
        flags: [String]?,
        phone: String?,
        code: String?,
        faceId: String?
    ) {
        self.key = key
        self.face = face
        self.flags = flags
        self.phone = phone
        self.code = code
        self.faceId = faceId
    }
}

struct APIPlog: Decodable, Equatable, Hashable {
    /// дата. Допустимые значения: "Y-m-d H:i:s"
    let date: Date
    let uuid: String
    let imageUuid: String?
    /// идентификатор объекта (домофона)
    let objectId: Int
    /// тип объекта (0 - домофон)
    let objectType: Int
    /// идентификатор нагрузки (двери). Допустимые значения: "0", "1", "2"
    let objectMechanizma: Int
    /// описание нагрузки (двери)
    let mechanizmaDescription: String
    let event: EventType
    let detail: String
    let detailX: DetailX?
    let previewURL: String?
    let previewImage: UIImage?
    
    private enum CodingKeys: String, CodingKey {
        case date
        case uuid
        case image
        case objectId
        case objectType
        case objectMechanizma
        case mechanizmaDescription
        case event
        case detail
        case detailX
        case preview
    }
    
    enum EventType: Int {
        case unanswered = 1 // – Неотвеченный вызов в домофон
        case answered = 2// – Отвеченный вызовы в домофон
        case rfid = 3 // – Открытие ключом (+id ключа)
        case app = 4 // – Открытия из приложения  (+id пользователя)
        case face = 5 // – Открытия по распознаванию лица  (+id дескриптора лица)
        case passcode = 6 // – Открытие по коду квартиры
        case call = 7 // – Открытие ворот по звонку (номер звонящего в тексте)
        case plate = 8 // – Открытие ворот по распознаванию номера (номер машины в тексте)
        case unknown = -1
    }
    
    static func == (lhs: APIPlog, rhs: APIPlog) -> Bool {
        guard let left = lhs.imageUuid,
              let right = rhs.imageUuid else {
            return lhs.uuid == rhs.uuid
        }
        
        return left == right
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let dateRawValue = try container.decode(String.self, forKey: .date)
        
        date = try dateRawValue.dateFromAPIString.unwrapped(or: NSError.APIWrapperError.noDataError)
        uuid = try container.decode(String.self, forKey: .uuid)
        imageUuid = try? container.decode(String.self, forKey: .image)
        
        objectId = try container.decode(Int.self, forKey: .objectId) 
        
        objectType = try container.decode(String.self, forKey: .objectType).int ?? -1
        objectMechanizma = try container.decode(String.self, forKey: .objectMechanizma).int ?? -1
        mechanizmaDescription = try container.decode(String.self, forKey: .mechanizmaDescription)
        event = APIPlog.EventType(rawValue: try container.decode(String.self, forKey: .event).int ?? -1) ?? .unknown
        detail = (try? container.decode(String.self, forKey: .detail)) ?? ""
        detailX = try? container.decode(DetailX.self, forKey: .detailX)
        
        previewURL = try? container.decode(String.self, forKey: .preview)
        
        if let previewURL = previewURL {
            previewImage = UIImage(base64URLString: previewURL)
        } else {
            previewImage = nil
        }
    }
    
    // пришлось добавить инициализатор для ручного создания объектов
    init(
        date: Date, // дата. Допустимые значения: "Y-m-d H:i:s"
        uuid: String,
        imageUuid: String?,
        objectId: Int, // идентификатор объекта (домофона)
        objectType: Int, // тип объекта (0 - домофон)
        objectMechanizma: Int, // идентификатор нагрузки (двери). Допустимые значения: "0", "1", "2"
        mechanizmaDescription: String, // описание нагрузки (двери)
        event: EventType,
        detail: String,
        detailX: DetailX?,
        previewURL: String?,
        previewImage: UIImage?
        ) {
        self.date = date
        self.uuid = uuid
        self.imageUuid = imageUuid
        self.objectId = objectId
        self.objectType = objectType
        self.objectMechanizma = objectMechanizma
        self.mechanizmaDescription = mechanizmaDescription
        self.event = event
        self.detail = detail
        self.detailX = detailX
        self.previewURL = previewURL
        self.previewImage = previewImage
    }
}
