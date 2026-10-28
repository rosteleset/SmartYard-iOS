//
//  OnboardingPageContent.swift
//  SmartYard
//
//  Created by Александр Попов on 29.09.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

struct OnboardingPageContent: View {
    @Environment(\.horizontalSizeClass)
    private var sizeClass

    let page: OnboardingPage

    var body: some View {
        GeometryReader { viewport in
            ScrollView {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 56) {
                        illustration
                        pageText(horizontal: true)
                            .frame(idealWidth: 480, maxWidth: 480)
                    }
                    .fixedSize(horizontal: true, vertical: false)

                    VStack(spacing: 32) {
                        illustration
                        pageText(horizontal: false)
                    }
                    .frame(maxWidth: 560)
                }
                .padding(.horizontal, sizeClass == .regular ? 32 : 30)
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity, minHeight: viewport.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .accessibilityIdentifier("onboarding.page.\(page.rawValue)")
    }

    private func pageText(horizontal: Bool) -> some View {
        VStack(alignment: horizontal ? .leading : .center, spacing: 12) {
            Text(verbatim: page.titleText)
                .font(SYFont.bold(size: sizeClass == .regular ? 34 : 32))
                .foregroundStyle(SYColor.semiBlack)
                .accessibilityAddTraits(.isHeader)

            Text(verbatim: page.subTitleText)
                .font(SYFont.regular(size: sizeClass == .regular ? 18 : 14))
                .foregroundStyle(SYColor.gray)
                .padding(.horizontal, sizeClass == .compact && !horizontal ? 30 : 0)
        }
        .multilineTextAlignment(horizontal ? .leading : .center)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var illustration: some View {
        let size: CGFloat = sizeClass == .regular ? 240 : 120
        return Image(page.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
