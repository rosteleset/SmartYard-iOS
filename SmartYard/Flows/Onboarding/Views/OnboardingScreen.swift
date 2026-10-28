//
//  OnboardingScreen.swift
//  SmartYard
//
//  Created by Александр Попов on 29.09.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

private enum OnboardingMetrics {
    static let pageIndicatorHeight: CGFloat = 77.0 / 3.0
}

struct OnboardingScreen: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @Environment(\.horizontalSizeClass)
    private var sizeClass
    let store: OnboardingStore

    private var selectedPage: Int { store.selectedPage }

    private var isLastPage: Bool {
        selectedPage == OnboardingPage.allCases.count - 1
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: Binding(get: { store.selectedPage }, set: store.selectPage)) {
                ForEach(OnboardingPage.allCases, id: \.rawValue) { page in
                    OnboardingPageContent(page: page)
                        .tag(page.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .accessibilityIdentifier("onboarding.pages")
            .safeAreaInset(edge: .bottom, spacing: 0) { footer }
            .background {
                SYColor.secondBackground
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        // The onboarding design uses the standard text size independently of system text settings.
        .dynamicTypeSize(.large)
        .background {
            Image("MainBackground")
                .resizable()
                .scaledToFill()
                .clipped()
                .ignoresSafeArea()
        }
    }

    @ViewBuilder private var header: some View {
        if sizeClass == .regular {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 32) {
                    logo(height: 80)
                    Spacer(minLength: 32)
                    skipButton
                }
                VStack(alignment: .trailing, spacing: 16) {
                    skipButton
                    logo(height: 80).frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        } else {
            VStack(spacing: 14) {
                skipButton
                    .frame(maxWidth: .infinity, alignment: .trailing)
                logo(height: 56)
            }
            .padding(.horizontal, 16)
            .padding(.top, 26)
            .padding(.bottom, 40)
        }
    }

    private func logo(height: CGFloat) -> some View {
        Image("AppNameLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 160, height: height)
            .accessibilityHidden(true)
    }

    private var skipButton: some View {
        Button(action: store.skip) {
            Text(verbatim: L10n.Onboarding.skipButton)
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .opacity(isLastPage ? 0 : 1)
        .allowsHitTesting(!isLastPage)
        .accessibilityHidden(isLastPage)
        .accessibilityIdentifier("onboarding.skip")
    }

    private var footer: some View {
        VStack(spacing: 40) {
            primaryAction
                .frame(maxWidth: 480)
                .padding(.horizontal, 40)
            pageIndicators
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .background(SYColor.secondBackground.ignoresSafeArea(edges: .bottom))
    }

    @ViewBuilder private var primaryAction: some View {
        let font = SYFont.semibold(size: 18)
        if isLastPage {
            Button(action: store.start) {
                Text(verbatim: L10n.Onboarding.coolLetSGetStartedButton)
            }
            .buttonStyle(SYPrimaryButtonStyle(font: font))
            .accessibilityIdentifier("onboarding.start")
        } else {
            Button(action: advancePage) {
                Text(verbatim: L10n.Common.next)
            }
            .buttonStyle(SYOutlineButtonStyle(font: font))
            .accessibilityIdentifier("onboarding.next")
        }
    }

    private var pageIndicators: some View {
        HStack(spacing: 10) {
            ForEach(OnboardingPage.allCases, id: \.rawValue) { page in
                Circle()
                    .fill(
                        page.rawValue == selectedPage
                            ? SYColor.blue
                            : SYColor.gray.opacity(0.2)
                    )
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 73, height: OnboardingMetrics.pageIndicatorHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: OnboardingPage.allCases[selectedPage].titleText))
        .accessibilityValue(Text(verbatim: "\(selectedPage + 1) / \(OnboardingPage.allCases.count)"))
        .accessibilityIdentifier("onboarding.pageIndicator")
    }

    private func advancePage() {
        guard !isLastPage else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            store.advance()
        }
    }
}
