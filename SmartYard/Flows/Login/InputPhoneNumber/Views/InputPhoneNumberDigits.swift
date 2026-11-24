//
//  InputPhoneNumberDigits.swift
//  SmartYard
//
//  Created by Александр Попов on 29.09.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI
import UIKit

struct InputPhoneNumberDigits: View {
    let prefix: String
    let digits: [Character]
    let gaps: [Bool]
    let maximumFontSize: CGFloat

    private let baseFontSize: CGFloat = 36
    private let baseSlotWidth: CGFloat = 22
    private let baseSidePadding: CGFloat = 4

    var body: some View {
        GeometryReader { viewport in
            if viewport.size.width > 0 {
                let scale = min(maximumFontSize / baseFontSize, viewport.size.width / baseRowWidth)
                digitRow(scale: scale)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // The dialing code and national number read left to right in every locale.
        .environment(\.layoutDirection, .leftToRight)
    }

    private var baseRowWidth: CGFloat {
        let font = UIFont.SourceSansPro.bold(size: baseFontSize)
        let prefixWidth = ("+" + prefix as NSString).size(withAttributes: [.font: font]).width.rounded(.up)
        let totalGapWidth = gaps.reduce(CGFloat.zero) { $0 + ($1 ? 12 : 2) }
        return prefixWidth + baseSlotWidth * CGFloat(gaps.count) + totalGapWidth + baseSidePadding * 2
    }

    private func digitRow(scale: CGFloat) -> some View {
        HStack(spacing: 0) {
            Text(verbatim: "+" + prefix)
                .fixedSize()
                .frame(height: 34 * scale)

            ForEach(gaps.indices, id: \.self) { index in
                Color.clear
                    .frame(width: baseSlotWidth * scale, height: 34 * scale)
                    .overlay {
                        if digits.indices.contains(index) {
                            Text(verbatim: String(digits[index]))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if !digits.indices.contains(index) {
                            SYColor.semiBlack.frame(height: max(1, scale))
                        }
                    }
                    .padding(.leading, (gaps[index] ? 12 : 2) * scale)
            }
        }
        .font(SYFont.bold(size: baseFontSize * scale))
        .foregroundStyle(SYColor.gray)
        .padding(.horizontal, baseSidePadding * scale)
    }
}
