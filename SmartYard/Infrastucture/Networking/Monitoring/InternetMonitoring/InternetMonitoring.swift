//
//  InternetMonitoring.swift
//  SmartYard
//
//  Created by Александр Попов on 19.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxSwift

protocol InternetMonitoring {
    var currentStatus: InternetStatus { get }
    var status: Observable<InternetStatus> { get }
}

enum InternetStatus: Equatable {
    case offline            // нет NWPath
    case online             // NWPath.satisfied (есть хоть какой-то маршрут)
}
