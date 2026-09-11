//
//  PlayerAttachable.swift
//  SmartYard
//
//  Created by Александр Попов on 08.01.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import UIKit

enum PlayerPresentation {
    case inline
    case fullscreen
}

protocol PlayerControlsAttachable: AnyObject {
    var playerControlsContainerView: UIView { get }
}

protocol PlayerAttachable: AnyObject {
    var playerContainerView: UIView { get }
    var playerPresentation: PlayerPresentation { get }
}

extension PlayerAttachable {
    var playerPresentation: PlayerPresentation { .inline }
}
