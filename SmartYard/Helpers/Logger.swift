//
//  Logger.swift
//  SmartYard
//
//  Created by Александр Попов on 24.12.2024.
//  Copyright © 2024 LanTa. All rights reserved.
//

import Foundation

enum LogLevel: String {
    case info = "ℹ️ [INFO]"
    case debug = "🛠️ [DEBUG]"
    case warning = "⚠️ [WARNING]"
    case error = "❌ [ERROR]"
    case critical = "🛑 [CRITICAL]"
    case success = "✅ [SUCCESS]"
}

enum LogMode {
    case verbose
    case errorsOnly
    case none
}

#if DEBUG
var currentLogMode: LogMode = .verbose
#else
var currentLogMode: LogMode = .errorsOnly
#endif

enum Logger {

    // MARK: - Public methods

    /// Логирует информационные сообщения для отслеживания выполнения программы.
    static func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        printLog(.info, message: message, file: file, function: function, line: line)
    }
    
    /// Логирует отладочные сообщения для диагностики и детального анализа.
    static func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        printLog(.debug, message: message, file: file, function: function, line: line)
    }
    
    /// Логирует отладочные сообщения для диагностики и детального анализа типа Any.
    static func logDebug(_ item: Any, file: String = #file, function: String = #function, line: Int = #line) {
        let string = String(describing: item)
        printLog(.debug, message: string, file: file, function: function, line: line)
    }
    
    /// Логирует отладочные сообщения для диагностики и детального анализа типа Encodable.
    static func logDebug<T: Encodable>(_ object: T, encoder: JSONEncoder = JSONEncoder(), file: String = #file, function: String = #function, line: Int = #line) {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(object),
           let json = String(data: data, encoding: .utf8) {
            printLog(.debug, message: json, file: file, function: function, line: line)
        } else {
            logDebug(object, file: file, function: function, line: line)
        }
    }

    /// Логирует предупреждения о потенциальных проблемах.
    static func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        printLog(.warning, message: message, file: file, function: function, line: line)
    }

    /// Логирует ошибки, которые требуют внимания, но не критичны.
    static func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        printLog(.error, message: message, file: file, function: function, line: line)
    }

    /// Логирует критические ошибки, из-за которых программа может не продолжить работу.
    static func logCritical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        printLog(.critical, message: message, file: file, function: function, line: line)
    }

    /// Логирует успешное выполнение ключевых операций.
    static func logSuccess(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        printLog(.success, message: message, file: file, function: function, line: line)
    }

    // MARK: - Private helpers
    
    private static func printLog(_ level: LogLevel, message: String, file: String, function: String, line: Int) {
        guard shouldLog(level) else { return }
        let fileName = (file as NSString).lastPathComponent
        let time = timestamp()
        let output = "\(level.rawValue) \(time) [\(fileName):\(line)] \(function) → \(message)"
        print(output)
    }

    private static func shouldLog(_ level: LogLevel) -> Bool {
        switch currentLogMode {
        case .none: return false
        case .errorsOnly: return [.error, .critical].contains(level)
        case .verbose: return true
        }
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
    
}
