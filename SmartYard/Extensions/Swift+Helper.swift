//
//  Swift+Helper.swift
//  SmartYard
//
//  Created by Александр Васильев on 18.10.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import FirebaseCrashlytics

///  Переопределённый метод, который в режиме отладки направляет вывод в консоль,
///  а в режиме релиза перенаправляет вывод в Crashlytics.log
///  
/// - Parameters:
///   - items: Zero or more items to print.
///   - separator: A string to print between each item. The default is a single
///     space (`" "`).
///   - terminator: The string to print after all items have been printed. The
///     default is a newline (`"\n"`).
public func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    Swift.print(
        items.map {
            String(describing: $0)
            .truncated(toLength: 1000)
        }
            .joined(separator: separator) + terminator,
        terminator: ""
    )
    #endif
    Crashlytics.crashlytics().log(
        items.map {
            String(describing: $0)
            .truncated(toLength: 1000)
            
        }
            .joined(separator: separator) + terminator)
}
