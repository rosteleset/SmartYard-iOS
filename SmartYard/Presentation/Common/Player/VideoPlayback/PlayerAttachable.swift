//
//  PlayerAttachable.swift
//  SmartYard
//
//  Created by Александр Попов on 08.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit

protocol PlayerAttachable: AnyObject {
    var playerContainerView: UIView { get }
}

protocol PlayerControlsAttachable: AnyObject {
    var playerControlsContainerView: UIView { get }
}
