//
//  PayStatusState.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 13.09.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

enum PayStatusState {
    case wait
    case error(title: String?, message: String?)
    case success(title: String, message: String)
}
