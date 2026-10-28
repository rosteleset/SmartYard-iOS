//
//  SYFont.swift
//  SmartYard
//
//  Created by Александр Попов on 28.10.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI
import UIKit

/// Fixed-size SwiftUI fonts resolved through the existing Source Sans Pro catalog.
enum SYFont {
    static func regular(size: CGFloat) -> Font {
        .custom(UIFont.SourceSansPro.regular(size: size).fontName, fixedSize: size)
    }

    static func semibold(size: CGFloat) -> Font {
        .custom(UIFont.SourceSansPro.semibold(size: size).fontName, fixedSize: size)
    }

    static func bold(size: CGFloat) -> Font {
        .custom(UIFont.SourceSansPro.bold(size: size).fontName, fixedSize: size)
    }
}
