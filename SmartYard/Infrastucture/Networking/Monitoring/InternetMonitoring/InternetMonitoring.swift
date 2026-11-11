//
//  InternetMonitoring.swift
//  SmartYard
//
//  Created by Александр Попов on 19.12.2025.
//  Copyright © 2025 Sesameware. All rights reserved.
//

import RxSwift

enum InternetStatus: Equatable {
    case offline            // нет NWPath
    case online             // NWPath.satisfied (есть хоть какой-то маршрут)
}

protocol InternetMonitoring {
    var currentStatus: InternetStatus { get }
    var status: Observable<InternetStatus> { get }
}
