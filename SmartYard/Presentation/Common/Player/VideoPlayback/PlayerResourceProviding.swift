//
//  PlayerResourceProviding.swift
//  SmartYard
//
//  Created by Александр Попов on 08.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import Foundation
import SmartYardVideoPlayer

typealias PlayerItemID = Int

protocol PlayerResourceProviding: AnyObject {
    func fetch(id: PlayerItemID, completion: @escaping (SYPlayerResource?) -> Void)
    func prefetch(id: PlayerItemID)
    func cancelPrefetch(id: PlayerItemID)
}
