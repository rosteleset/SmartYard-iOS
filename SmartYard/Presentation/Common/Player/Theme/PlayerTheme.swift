//
//  PlayerTheme.swift
//  SmartYard
//
//  Created by Александр Попов on 06.02.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit
import SmartYardVideoPlayer

struct PlayerTheme {
    var colors: Colors
    var fonts: Fonts
    var icons: Icons

    var logs: Bool = false {
        willSet {
            SYPlayerConfig.shared.allowLogs = newValue
        }
    }

    init(
        colors: Colors = .default,
        fonts: Fonts = .default,
        icons: Icons = .default,
        logs: Bool = false
    ) {
        self.colors = colors
        self.fonts = fonts
        self.icons = icons
        self.logs = logs
    }
}

// MARK: - Colors

extension PlayerTheme {
    struct Colors {
        var borderColor: UIColor
        var accentColor: UIColor
        var textColor: UIColor
        var playerBackgroundColor: UIColor
        var controlsTextColor: UIColor
        var controlsTintColor: UIColor
        var controlsMaskVisibleColor: UIColor
        var thumbnailsBackgroundColor: UIColor
        var periodPickerBorderColor: UIColor
        var webRTCTransportColor: UIColor
        var hlsTransportColor: UIColor
        var transportPlayingColor: UIColor
        var transportWarningColor: UIColor
        var transportErrorColor: UIColor
        var transportBadgeBackgroundColor: UIColor
        var transportMessageBackgroundColor: UIColor

        static let `default` = Colors(
            borderColor: .SmartYard.grayBorder,
            accentColor: .white,
            textColor: .SmartYard.semiBlack,
            playerBackgroundColor: .black,
            controlsTextColor: .white,
            controlsTintColor: .white,
            controlsMaskVisibleColor: UIColor.black.withAlphaComponent(0.4),
            thumbnailsBackgroundColor: UIColor.black.withAlphaComponent(0.5),
            periodPickerBorderColor: UIColor(white: 0.7, alpha: 1.0),
            webRTCTransportColor: UIColor(red: 0.18, green: 0.78, blue: 1.0, alpha: 1.0),
            hlsTransportColor: UIColor(red: 1.0, green: 0.64, blue: 0.20, alpha: 1.0),
            transportPlayingColor: UIColor(red: 0.28, green: 0.84, blue: 0.48, alpha: 1.0),
            transportWarningColor: UIColor(red: 1.0, green: 0.76, blue: 0.24, alpha: 1.0),
            transportErrorColor: UIColor(red: 1.0, green: 0.31, blue: 0.31, alpha: 1.0),
            transportBadgeBackgroundColor: UIColor.black.withAlphaComponent(0.52),
            transportMessageBackgroundColor: UIColor.black.withAlphaComponent(0.76)
        )
    }
}

// MARK: - Fonts

extension PlayerTheme {
    struct Fonts {
        var titleFont: UIFont
        var speedButtonFont: UIFont
        var timeLabelFont: UIFont
        var periodPickerFont: UIFont
        var periodPickerSelectedFont: UIFont
        var transportBadgeFont: UIFont
        var transportMessageFont: UIFont

        static let `default` = Fonts(
            titleFont: .SourceSansPro.semibold(size: 24),
            speedButtonFont: .SourceSansPro.regular(size: 20),
            timeLabelFont: .SourceSansPro.semibold(size: 12),
            periodPickerFont: .SourceSansPro.regular(size: 14),
            periodPickerSelectedFont: .SourceSansPro.bold(size: 20),
            transportBadgeFont: .SourceSansPro.semibold(size: 12),
            transportMessageFont: .SourceSansPro.semibold(size: 14)
        )
    }
}

// MARK: - Icons

extension PlayerTheme {
    struct Icons {
        var fullscreenEnter: UIImage?
        var fullscreenExit: UIImage?
        var play: UIImage?
        var pause: UIImage?
        var soundOn: UIImage?
        var soundOff: UIImage?
        var rangeSliderStart: UIImage?
        var rangeSliderEnd: UIImage?
        var rangeSliderProgress: UIImage?

        // user for custom 
        static let `default` = Icons(
            fullscreenEnter: nil,
            fullscreenExit: nil,
            play: nil,
            pause: nil,
            soundOn: nil,
            soundOff: nil,
            rangeSliderStart: nil,
            rangeSliderEnd: nil,
            rangeSliderProgress: nil
        )
    }
}

extension PlayerTheme {

    func applyToSharedPlayerConfig() {
        SYPlayerConfig.shared.allowLogs = logs

        // Colors
        var syColors = SYPlayerColors()
        syColors.borderColor = colors.borderColor
        syColors.accentColor = colors.accentColor
        syColors.textColor = colors.textColor
        syColors.playerBackgroundColor = colors.playerBackgroundColor
        syColors.controlsTextColor = colors.controlsTextColor
        syColors.controlsTintColor = colors.controlsTintColor
        syColors.controlsMaskVisibleColor = colors.controlsMaskVisibleColor
        syColors.thumbnailsBackgroundColor = colors.thumbnailsBackgroundColor
        syColors.periodPickerBorderColor = colors.periodPickerBorderColor
        SYPlayerConfig.shared.colors = syColors

        // Fonts
        var syFonts = SYPlayerFonts()
        syFonts.titleFont = fonts.titleFont
        syFonts.speedButtonFont = fonts.speedButtonFont
        syFonts.timeLabelFont = fonts.timeLabelFont
        syFonts.periodPickerFont = fonts.periodPickerFont
        syFonts.periodPickerSelectedFont = fonts.periodPickerSelectedFont
        SYPlayerConfig.shared.fonts = syFonts

        // Transport status
        SYPlayerConfig.shared.transportAppearance = SYPlayerTransportAppearance(
            webRTCColor: colors.webRTCTransportColor,
            hlsColor: colors.hlsTransportColor,
            playingColor: colors.transportPlayingColor,
            warningColor: colors.transportWarningColor,
            errorColor: colors.transportErrorColor,
            badgeBackgroundColor: colors.transportBadgeBackgroundColor,
            messageBackgroundColor: colors.transportMessageBackgroundColor,
            textColor: colors.controlsTextColor,
            badgeFont: fonts.transportBadgeFont,
            messageFont: fonts.transportMessageFont
        )
        SYPlayerConfig.shared.transportStrings = SYPlayerTransportStrings(
            connecting: L10n.Player.Transport.connecting,
            connectingWebRTC: L10n.Player.Transport.connectingWebRTC,
            connectingHLS: L10n.Player.Transport.connectingHLS,
            switchingToHLS: L10n.Player.Transport.switchingToHLS,
            connectedHLS: L10n.Player.Transport.connectedHLS,
            videoUnavailable: L10n.Player.Transport.videoUnavailable,
            webRTCInfo: L10n.Player.Transport.webRTCInfo,
            hlsInfo: L10n.Player.Transport.hlsInfo,
            lowLatencyHLSInfo: L10n.Player.Transport.lowLatencyHLSInfo
        )

        // Icons
        var syIcons = SYPlayerIcons()
        syIcons.fullscreenEnter = icons.fullscreenEnter
        syIcons.fullscreenExit = icons.fullscreenExit
        syIcons.play = icons.play
        syIcons.pause = icons.pause
        syIcons.soundOn = icons.soundOn
        syIcons.soundOff = icons.soundOff
        syIcons.rangeSliderStart = icons.rangeSliderStart
        syIcons.rangeSliderEnd = icons.rangeSliderEnd
        syIcons.rangeSliderProgress = icons.rangeSliderProgress
        SYPlayerConfig.shared.icons = syIcons
    }
}
