//
//  SYOutlineButtonStyle.swift
//  SmartYard
//
//  Created by Александр Попов on 27.10.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

/// The existing WhiteButtonWithBorder appearance.
struct SYOutlineButtonStyle: ButtonStyle {
    private let font: Font

    init(font: Font = SYFont.semibold(size: 18)) {
        self.font = font
    }

    @Environment(\.isEnabled)
    private var isEnabled

    private var foreground: Color {
        isEnabled ? SYColor.blue
            : SYColor.gray.opacity(0.5)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(foreground)
            .opacity(configuration.isPressed ? 0.3 : 1)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                SYColor.secondBackground,
                in: RoundedRectangle(cornerRadius: 12, style: .circular)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .circular)
                    .strokeBorder(foreground, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .circular))
    }
}
