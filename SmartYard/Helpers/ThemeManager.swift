//
//  ThemeManager.swift
//  SmartYard
//
//  Created by Александр Попов on 12.11.2024.
//  Copyright © 2024 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

private let appearanceModeKey = "themeAppearanceKey"

final class ThemeManager {
    static let shared = ThemeManager()
    private let disposeBag = DisposeBag()

    private(set) var currentTheme: BehaviorRelay<UIUserInterfaceStyle> = {
        let savedThemeIndex = UserDefaults.standard.integer(forKey: appearanceModeKey)
        let initialTheme = ThemeManager.userInterfaceStyle(for: savedThemeIndex)
        return BehaviorRelay(value: initialTheme)
    }()

    private init() {
        applySavedTheme()
        
        currentTheme
            .distinctUntilChanged()
            .subscribe(onNext: { style in
                UIApplication.shared.windows.forEach { window in
                    window.overrideUserInterfaceStyle = style
                }
            })
            .disposed(by: disposeBag)
    }

    func setTheme(_ style: UIUserInterfaceStyle) {
        guard style != currentTheme.value else {
            Logger.logInfo("Тема уже установлена: \(style). Изменений не требуется.")
            return
        }
        currentTheme.accept(style)
        saveTheme(style)
        Logger.logSuccess("Тема обновлена на: \(style).")
    }

    func applySavedTheme() {
        let savedTheme = loadSavedTheme()
        currentTheme.accept(savedTheme)
        applyTheme(savedTheme)
    }

    private func applyTheme(_ style: UIUserInterfaceStyle) {
        Logger.logInfo("Применение темы: \(style).")
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = style
        }
    }

    private func saveTheme(_ style: UIUserInterfaceStyle) {
        let index = ThemeManager.indexForUserInterfaceStyle(style)
        UserDefaults.standard.set(index, forKey: appearanceModeKey)
        Logger.logDebug("Индекс темы \(index) сохранён в UserDefaults.")
    }

    private func loadSavedTheme() -> UIUserInterfaceStyle {
        let savedIndex = UserDefaults.standard.integer(forKey: appearanceModeKey)
        let style = ThemeManager.userInterfaceStyle(for: savedIndex)
        Logger.logDebug("Загружен индекс темы: \(savedIndex), стиль: \(style).")
        return style
    }

    private static func indexForUserInterfaceStyle(_ style: UIUserInterfaceStyle) -> Int {
        switch style {
        case .unspecified: return 0
        case .light: return 1
        case .dark: return 2
        @unknown default:
            Logger.logWarning("Неизвестный стиль интерфейса: \(style). Установлено значение по умолчанию (0).")
            return 0
        }
    }

    private static func userInterfaceStyle(for index: Int) -> UIUserInterfaceStyle {
        Logger.logDebug("Конвертация индекса \(index) в UIUserInterfaceStyle.")
        switch index {
        case 0: return .unspecified
        case 1: return .light
        case 2: return .dark
        default: return .unspecified
        }
    }
}
