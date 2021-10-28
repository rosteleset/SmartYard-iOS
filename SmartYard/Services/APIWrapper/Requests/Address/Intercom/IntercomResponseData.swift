//
//  HourGuestAccessResponseData.swift
//  SmartYard
//
//  Created by Mad Brains on 21.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct IntercomResponseData: Decodable {
    
    let allowDoorCode: Bool
    let doorCode: String?
    let cms: Bool
    let voip: Bool
    let autoOpen: Date
    let whiteRabbit: Bool
    let paperBill: Bool?
    let disablePlog: Bool?
    let hiddenPlog: Bool?
    let frsDisabled: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case allowDoorCode
        case doorCode
        case cms = "CMS"
        case voip = "VoIP"
        case autoOpen
        case whiteRabbit
        case paperBill
        case disablePlog
        case hiddenPlog
        case frsDisabled = "FRSDisabled"
    }
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let allowDoorCodeRawValue = try container.decode(String.self, forKey: .allowDoorCode)

        switch allowDoorCodeRawValue {
        case "t": allowDoorCode = true
        case "f": allowDoorCode = false
        default: throw NSError.APIWrapperError.noDataError
        }
        
        doorCode = try? container.decode(String.self, forKey: .doorCode)
        
        let cmsRawValue = try container.decode(String.self, forKey: .cms)
        
        switch cmsRawValue {
        case "t": cms = true
        case "f": cms = false
        default: throw NSError.APIWrapperError.noDataError
        }
        
        let voipRawValue = try container.decode(String.self, forKey: .voip)
        
        switch voipRawValue {
        case "t": voip = true
        case "f": voip = false
        default: throw NSError.APIWrapperError.noDataError
        }
        
        let autoOpenRawValue = try container.decode(String.self, forKey: .autoOpen)
        autoOpen = try autoOpenRawValue.dateFromAPIString.unwrapped(or: NSError.APIWrapperError.noDataError)
        
        let whiteRabbitRawValue = try container.decode(String.self, forKey: .whiteRabbit)
        switch whiteRabbitRawValue {
        case "1", "2", "3", "5", "7", "10": whiteRabbit = true
        case "0": whiteRabbit = false
        default: throw NSError.APIWrapperError.noDataError
        }
        
        let paperBillRawValue = try? container.decode(String.self, forKey: .paperBill)
        
        switch paperBillRawValue {
        case "t": paperBill = true
        case "f": paperBill = false
        default: paperBill = nil
        }
        
        let disablePlogRawValue = try? container.decode(String.self, forKey: .disablePlog)
        
        switch disablePlogRawValue {
        case "t": disablePlog = true
        case "f": disablePlog = false
        default: disablePlog = nil
        }
        
        let hiddenPlogRawValue = try? container.decode(String.self, forKey: .hiddenPlog)
        
        switch hiddenPlogRawValue {
        case "t": hiddenPlog = true
        case "f": hiddenPlog = false
        default: hiddenPlog = nil
        }
        
        let frsDisabledRawValue = try? container.decode(String.self, forKey: .frsDisabled)
        
        switch frsDisabledRawValue {
        case "t": frsDisabled = true
        case "f": frsDisabled = false
        default: frsDisabled = nil
        }
    }
    
}
