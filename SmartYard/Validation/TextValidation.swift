//
//  TextValidation.swift
//  SmartYard
//
//  Created by Александр Попов on 22.09.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

protocol TextValidation {
    func validate(_ text: String) -> Bool
    var errorMessage: String? { get }
}
