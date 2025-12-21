//
//  NetworkStateProviding.swift
//  SmartYard
//
//  Created by Александр Попов on 19.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxSwift

protocol NetworkStateProviding {
    var state: Observable<NetworkState> { get }
    var currentState: NetworkState { get }
}
