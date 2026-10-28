//
//  SYPrimaryButtonStyle.swift
//  SmartYard
//
//  Created by Александр Попов on 27.10.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

/// The existing BlueButton appearance, shared by native SwiftUI screens.
struct SYPrimaryButtonStyle: ButtonStyle {
    private let font: Font
    private let height: CGFloat

    init(font: Font = SYFont.semibold(size: 18), height: CGFloat = 60) {
        self.font = font
        self.height = height
    }

    @Environment(\.isEnabled)
    private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(SYColor.secondBackground)
            .opacity(configuration.isPressed ? 0.3 : 1)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                isEnabled ? SYColor.blue : SYColor.gray.opacity(0.5),
                in: RoundedRectangle(cornerRadius: 12, style: .circular)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .circular))
    }
}
