//
//  SberbankRegisterResponseData.swift
//  SmartYard
//
//  Created by Александр Васильев on 14.03.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

import Foundation

struct SberbankRegisterResponseData: Codable {
    
    let success: Bool
    let data: SberbankRegisterData?
    let error: SberbankRegisterError?
}
