//
//  CircleIconStyle.swift
//  SmartYard
//
//  Created by Александр Попов on 01.10.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit

struct CircleIconStyle {
    let image: UIImage?
    let circleColor: UIColor
    let iconColor: UIColor
    let borderColor: UIColor?
    let borderWidth: CGFloat
}

extension CircleIconStyle {
    enum Icon: String, CaseIterable {
        /// settings
        case call = "SettingsCall"
        case eye = "SettingsEye"
        case key = "SettingsKey"
        case monitor = "SettingsMonitor"
        case wifi = "SettingsWiFi"
        /// close
        case closeRed = "CloseRed"
        case closeBlue = "CloseBlue"
        /// others
        case cam = "Cam"
        case question = "Question"

        var image: UIImage? { UIImage(named: rawValue) }
    }

    enum Settings {
        private static func style(for icon: UIImage?, selected: Bool) -> CircleIconStyle {
            CircleIconStyle(
                image: icon,
                circleColor: selected ? .SmartYard.blue : .SmartYard.gray.withAlphaComponent(0.4),
                iconColor: .SmartYard.secondBackgroundColor,
                borderColor: nil,
                borderWidth: 0
            )
        }

        enum Selected {
            static let call = style(for: Icon.call.image, selected: true)
            static let eye = style(for: Icon.eye.image, selected: true)
            static let key = style(for: Icon.key.image, selected: true)
            static let monitor = style(for: Icon.monitor.image, selected: true)
            static let wifi = style(for: Icon.wifi.image, selected: true)
        }
        enum Unselected {
            static let call = style(for: Icon.call.image, selected: false)
            static let eye = style(for: Icon.eye.image, selected: false)
            static let key = style(for: Icon.key.image, selected: false)
            static let monitor = style(for: Icon.monitor.image, selected: false)
            static let wifi = style(for: Icon.wifi.image, selected: false)
        }
    }

    enum Close {
        private static func style(for icon: UIImage?, isRed: Bool) -> CircleIconStyle {
            CircleIconStyle(
                image: icon,
                circleColor: .SmartYard.grayBorder,
                iconColor: isRed ? .SmartYard.incorrectDataRed : .SmartYard.blue,
                borderColor: nil,
                borderWidth: 0
            )
        }

        static let red = style(for: Icon.closeRed.image, isRed: true)
        static let blue = style(for: Icon.closeBlue.image, isRed: false)
    }

    enum Others {
        static let cam = CircleIconStyle(
            image: Icon.cam.image,
            circleColor: .SmartYard.blue,
            iconColor: .SmartYard.secondBackgroundColor,
            borderColor: .SmartYard.secondBackgroundColor,
            borderWidth: 1
        )

        static let question = CircleIconStyle(
            image: Icon.question.image,
            circleColor: .SmartYard.blue,
            iconColor: .SmartYard.secondBackgroundColor,
            borderColor: nil,
            borderWidth: 0
        )
    }
}
