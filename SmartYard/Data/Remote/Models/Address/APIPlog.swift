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
        
        guard let left = Int(try container.decode(String.self, forKey: .left)),
              let top = Int(try container.decode(String.self, forKey: .top)),
              let width = Int(try container.decode(String.self, forKey: .width)),
              let height = Int(try container.decode(String.self, forKey: .height)) else {
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
    struct Vehicle: Decodable, Equatable, Hashable {
        let vehicleBox: [Int]?
        let plateKeyPoints: [Int]?
        let plateNumber: String?
    }

    let key: String?
    let face: Rectangle?
    let flags: [String]?
    let phone: String?
    let code: String?
    let faceId: String?
    let vehicle: Vehicle?
    
    private enum CodingKeys: String, CodingKey {
        case key
        case face
        case flags
        case phone
        case code
        case faceId
        case vehicle
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        key = try? container.decode(String.self, forKey: .key)
        face = try? container.decode(Rectangle.self, forKey: .face)
        flags = try? container.decode([String].self, forKey: .flags)
        phone = try? container.decode(String.self, forKey: .phone)
        code = try? container.decode(String.self, forKey: .code)
        faceId = try? container.decode(String.self, forKey: .faceId)
        vehicle = try? container.decode(Vehicle.self, forKey: .vehicle)
     }
    
    //пришлось добавить инициализатор для ручного создания объектов
    init(
        key: String?,
        face: Rectangle?,
        flags: [String]?,
        phone: String?,
        code: String?,
        faceId: String?,
        vehicle: Vehicle? = nil
    ) {
        self.key = key
        self.face = face
        self.flags = flags
        self.phone = phone
        self.code = code
        self.faceId = faceId
        self.vehicle = vehicle
    }
}

struct APIPlog: Decodable, Equatable, Hashable {
    /// дата. Допустимые значения: "Y-m-d H:i:s"
    let date: Date
    let uuid: String
    let imageUuid: String?
    let flatId: Int?
    /// идентификатор объекта (домофона)
    let objectId: Int
    /// тип объекта (0 - домофон)
    let objectType: Int
    /// идентификатор нагрузки (двери). Допустимые значения: "0", "1", "2"
    let objectMechanizma: Int
    /// описание нагрузки (двери)
    let mechanizmaDescription: String
    /// идентификатор дома
    let houseId: Int?
    /// идентификатор входа
    let entranceId: Int?
    /// идентификатор камеры
    let cameraId: Int?
    let event: EventType
    let detail: String
    let detailX: DetailX?
    let previewURL: String?
    let previewImage: UIImage?
    
    private enum CodingKeys: String, CodingKey {
        case date
        case uuid
        case image
        case flatId
        case objectId
        case objectType
        case objectMechanizma
        case mechanizmaDescription
        case event
        case houseId
        case entranceId
        case cameraId
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
        case reserved = 8 // – Зарезервировано для будущего использования
        case plate = 9 // – Открытие ворот по распознаванию номера (номер машины в тексте)
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
        flatId = try? container.decodeFlexibleInt(forKey: .flatId)
        objectId = try container.decode(String.self, forKey: .objectId).int ?? -1
        objectType = try container.decode(String.self, forKey: .objectType).int ?? -1
        objectMechanizma = try container.decode(String.self, forKey: .objectMechanizma).int ?? -1
        mechanizmaDescription = try container.decode(String.self, forKey: .mechanizmaDescription)
        houseId = try? container.decode(String.self, forKey: .houseId).int ?? nil
        entranceId = try? container.decode(String.self, forKey: .entranceId).int ?? nil
        cameraId = try? container.decode(String.self, forKey: .cameraId).int ?? nil
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
        flatId: Int?,
        objectId: Int, // идентификатор объекта (домофона)
        objectType: Int, // тип объекта (0 - домофон)
        objectMechanizma: Int, // идентификатор нагрузки (двери). Допустимые значения: "0", "1", "2"
        mechanizmaDescription: String, // описание нагрузки (двери)
        houseId: Int?,
        entranceId: Int?,
        cameraId: Int?,
        event: EventType,
        detail: String,
        detailX: DetailX?,
        previewURL: String?,
        previewImage: UIImage?
        ) {
        self.date = date
        self.uuid = uuid
        self.imageUuid = imageUuid
        self.flatId = flatId
        self.objectId = objectId
        self.objectType = objectType
        self.objectMechanizma = objectMechanizma
        self.mechanizmaDescription = mechanizmaDescription
        self.houseId = houseId
        self.entranceId = entranceId
        self.cameraId = cameraId
        self.event = event
        self.detail = detail
        self.detailX = detailX
        self.previewURL = previewURL
        self.previewImage = previewImage
    }

    func withFallbackFlatId(_ fallbackFlatId: Int) -> APIPlog {
        return APIPlog(
            date: date,
            uuid: uuid,
            imageUuid: imageUuid,
            flatId: flatId ?? fallbackFlatId,
            objectId: objectId,
            objectType: objectType,
            objectMechanizma: objectMechanizma,
            mechanizmaDescription: mechanizmaDescription,
            houseId: houseId,
            entranceId: entranceId,
            cameraId: cameraId,
            event: event,
            detail: detail,
            detailX: detailX,
            previewURL: previewURL,
            previewImage: previewImage
        )
    }
}

struct APITrackedEvent: Decodable, Equatable {
    let watcherId: Int
    let flatId: Int
    let eventType: Int
    let eventDetail: String?
    let comments: String?

    var normalizedEventDetail: String { eventDetail ?? "" }
    var normalizedComments: String { comments ?? "" }
    var key: String {
        ParanoidEventTracking.key(
            flatId: flatId,
            eventType: eventType,
            eventDetail: normalizedEventDetail
        )
    }
}

struct TrackEventResponseData: Decodable {
    let watcherId: Int
}

enum ParanoidEventTracking {
    static let supportedEventTypes: Set<Int> = [
        APIPlog.EventType.rfid.rawValue,
        APIPlog.EventType.app.rawValue,
        APIPlog.EventType.passcode.rawValue,
        APIPlog.EventType.plate.rawValue
    ]

    static func isSupported(_ event: APIPlog) -> Bool {
        guard event.flatId != nil else { return false }
        return supportedEventTypes.contains(event.event.rawValue)
    }

    static func eventDetail(from event: APIPlog) -> String {
        switch event.event {
        case .rfid:
            return event.detailX?.key ?? ""
        case .app:
            return event.detailX?.phone ?? ""
        case .passcode:
            return ""
        case .plate:
            return event.detailX?.vehicle?.plateNumber ?? ""
        case .unanswered, .answered, .face, .call, .reserved, .unknown:
            return ""
        }
    }

    static func key(flatId: Int, eventType: Int, eventDetail: String) -> String {
        return "\(flatId)_\(eventType)_\(eventDetail)"
    }

    static func key(for event: APIPlog) -> String? {
        guard let flatId = event.flatId else { return nil }
        return key(
            flatId: flatId,
            eventType: event.event.rawValue,
            eventDetail: eventDetail(from: event)
        )
    }

    static func title(for eventType: Int) -> String {
        switch eventType {
        case APIPlog.EventType.rfid.rawValue:
            return L10n.History.Event.openingWithKey
        case APIPlog.EventType.app.rawValue:
            return L10n.History.Event.openingFromApp
        case APIPlog.EventType.passcode.rawValue:
            return L10n.History.Event.openingWithCode
        case APIPlog.EventType.plate.rawValue:
            return L10n.History.Event.gateOpeningByNumberplate
        default:
            return L10n.History.Event.unknown
        }
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleInt(forKey key: Key) throws -> Int {
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key),
           let intValue = Int(value) {
            return intValue
        }
        throw NSError.APIWrapperError.noDataError
    }
}
