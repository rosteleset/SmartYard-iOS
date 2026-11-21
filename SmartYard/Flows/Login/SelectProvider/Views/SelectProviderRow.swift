//
//  SelectProviderRow.swift
//  SmartYard
//
//  Created by Александр Попов on 29.09.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

struct SelectProviderRow: View {
    let item: ProviderCellModel
    let showsSeparator: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 15) {
                checkBox
                Text(verbatim: item.provider.name)
                    .font(SYFont.semibold(size: 18))
                    .foregroundStyle(SYColor.semiBlack)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
            .frame(minHeight: 80)
            .frame(maxWidth: .infinity)
            .contentShape(SwiftUI.Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Color(uiColor: .SmartYard.grayBorder)
                    .frame(height: 1)
                    .padding(.horizontal, 16)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: item.provider.name))
        .accessibilityAddTraits(item.state == .checkedActive ? [.isSelected] : [])
        .accessibilityIdentifier("provider.row.\(item.provider.id)")
    }

    private var checkBox: some View {
        ZStack {
            Image("CheckBoxBorder")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color(uiColor: item.state.borderTintColor ?? .clear))
                .frame(width: 28, height: 28)
            Image("CheckIcon")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color(uiColor: item.state.checkTintColor ?? .clear))
                .frame(width: 14, height: 11)
        }
        .frame(width: 28, height: 28)
        .accessibilityHidden(true)
    }
}
