//
//  SmartYardSegmentControlViewProtocol.swift
//  SmartYard
//
//  Created by Александр Попов on 26.09.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit

protocol SmartYardSegmentControlViewProtocol: AnyObject {

    var segmentControl: UISegmentedControl { get }
    var titles: [String] { get set }

}
