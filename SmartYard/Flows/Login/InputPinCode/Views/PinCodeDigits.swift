//
//  PinCodeDigits.swift
//  SmartYard
//
//  Created by Александр Попов on 29.09.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

struct PinCodeDigits: View {
    let digits: [Character]
    let isCorrect: Bool
    let maximumFontSize: CGFloat

    private let baseFontSize: CGFloat = 36
    private let baseSlotWidth: CGFloat = 40
    private let baseSpacing: CGFloat = 6
    private let baseTrailingPadding: CGFloat = 2

    var body: some View {
        GeometryReader { viewport in
            if viewport.size.width > 0 {
                let scale = min(maximumFontSize / baseFontSize, viewport.size.width / baseRowWidth)
                digitRow(scale: scale)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private var baseRowWidth: CGFloat {
        let slotCount = CGFloat(Constants.pinLength)
        return slotCount * baseSlotWidth + max(0, slotCount - 1) * baseSpacing + baseTrailingPadding
    }

    private func digitRow(scale: CGFloat) -> some View {
        HStack(spacing: baseSpacing * scale) {
            ForEach(0..<Constants.pinLength, id: \.self) { index in
                VStack(spacing: scale) {
                    Text(verbatim: digits.indices.contains(index) ? String(digits[index]) : "")
                        .font(SYFont.bold(size: baseFontSize * scale))
                        .foregroundStyle(SYColor.gray)
                        .fixedSize()
                        .frame(width: baseSlotWidth * scale, height: 43 * scale)
                    SwiftUI.Rectangle()
                        .fill(Color(uiColor: isCorrect ? .SmartYard.semiBlack : .SmartYard.incorrectDataRed))
                        .frame(width: baseSlotWidth * scale, height: max(1, scale))
                }
            }
        }
        .padding(.trailing, baseTrailingPadding * scale)
    }
}
