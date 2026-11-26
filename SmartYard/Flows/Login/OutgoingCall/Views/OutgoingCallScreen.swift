//
//  OutgoingCallScreen.swift
//  SmartYard
//
//  Created by Александр Попов on 26.11.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

struct OutgoingCallScreen: View {
    let store: OutgoingCallStore

    @State private var showsLoadingIndicator = false
    @State private var isAnimatingLoadingIndicator = false

    private let callButtonHeight: CGFloat = 60
    private let footerBottomInset: CGFloat = 28

    var body: some View {
        GeometryReader { viewport in
            let narrowTablet = UIDevice.current.userInterfaceIdiom == .pad && viewport.size.width < 520
            let compact = viewport.size.height < 470
            let roomy = viewport.size.width >= 620
            let windowControlsInset: CGFloat = narrowTablet ? 20 : 0

            VStack(spacing: 0) {
                backBar(iconOnly: narrowTablet)
                    .padding(.top, windowControlsInset)
                    .frame(height: (compact || narrowTablet ? 44 : 69) + windowControlsInset)

                panel(bottomSafeArea: viewport.safeAreaInsets.bottom, compact: compact, roomy: roomy)
            }
            .allowsHitTesting(!blocksInteraction)
            .accessibilityHidden(blocksInteraction)
        }
        .overlay {
            if showsLoadingIndicator {
                loadingOverlay.transition(.opacity)
            }
        }
        .background {
            GeometryReader { viewport in
                Image("MainBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: viewport.size.width, height: viewport.size.height)
                    .clipped()
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea()
        }
        .onChange(of: store.isLoading, initial: true) { updateLoadingIndicator() }
        .dynamicTypeSize(.large)
    }

    private var blocksInteraction: Bool {
        store.isLoading || showsLoadingIndicator || isAnimatingLoadingIndicator
    }

    private func backBar(iconOnly: Bool) -> some View {
        HStack(spacing: 0) {
            Button(action: store.goBack) {
                HStack(spacing: 8) {
                    Image("BackArrowIcon").renderingMode(.template)
                    if !iconOnly {
                        Text(verbatim: L10n.Common.back).font(.system(size: 17))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(minWidth: iconOnly ? 44 : 152, maxHeight: .infinity, alignment: .leading)
                .contentShape(SwiftUI.Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: L10n.Common.back))
            .accessibilityIdentifier("outgoing-call.back")

            Spacer(minLength: 0)
        }
    }

    private func panel(bottomSafeArea: CGFloat, compact: Bool, roomy: Bool) -> some View {
        VStack(spacing: 0) {
            GeometryReader { viewport in
                ScrollView {
                    let panelHeight = viewport.size.height + callButtonHeight + footerBottomInset + bottomSafeArea
                    ContentLayout(viewportHeight: viewport.size.height, numberCenter: panelHeight / 2) {
                        phoneControls(compact: compact, roomy: roomy)
                        instruction(L10n.Auth.CallVerification.callInstructionPrefix, roomy: roomy)
                        confirmationNumber(roomy: roomy)
                        instruction(L10n.Auth.CallVerification.callInstructionSuffix, roomy: roomy)
                    }
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            Button(action: store.makeCall) {
                Text(verbatim: L10n.Auth.CallVerification.callButton)
            }
            .buttonStyle(SYPrimaryButtonStyle(font: SYFont.semibold(size: roomy ? 20 : 18), height: callButtonHeight))
            .padding(.horizontal, 40)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .padding(.bottom, footerBottomInset)
            .accessibilityIdentifier("outgoing-call.call")
        }
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12)
                .fill(SYColor.secondBackground)
                .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        }
    }

    private func phoneControls(compact: Bool, roomy: Bool) -> some View {
        VStack(spacing: compact ? 12 : 28) {
            Text(verbatim: store.phoneHint)
                .font(SYFont.regular(size: roomy ? 20 : 15))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("outgoing-call.phone-hint")

            Button(action: store.fixPhoneNumber) {
                Text(verbatim: L10n.Auth.CallVerification.editPhoneButton)
                    .font(SYFont.regular(size: roomy ? 18 : 16))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 33)
                    .contentShape(SwiftUI.Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("outgoing-call.fix-phone")
        }
        .foregroundStyle(SYColor.gray)
        .padding(.horizontal, 24)
        .padding(.top, compact ? 16 : 36)
    }

    private func instruction(_ title: String, roomy: Bool) -> some View {
        Text(verbatim: title)
            .font(SYFont.regular(size: roomy ? 20 : 18))
            .foregroundStyle(SYColor.gray)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
    }

    private func confirmationNumber(roomy: Bool) -> some View {
        Button(action: store.copyConfirmationPhone) {
            Text(verbatim: store.confirmationPhone)
                .font(SYFont.semibold(size: roomy ? 28 : 22))
                .foregroundStyle(SYColor.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .contentShape(SwiftUI.Rectangle())
                .environment(\.layoutDirection, .leftToRight)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("outgoing-call.confirmation-phone")
    }

    private var loadingOverlay: some View {
        ProgressView()
            .controlSize(.large)
            .tint(.white)
            .frame(width: 77, height: 77)
            .background {
                let card = RoundedRectangle(cornerRadius: 10)
                card.fill(.regularMaterial).overlay { card.fill(.white.opacity(0.035)) }
            }
            .environment(\.colorScheme, .dark)
            .accessibilityIdentifier("outgoing-call.loading")
    }

    private func updateLoadingIndicator() {
        guard !isAnimatingLoadingIndicator, showsLoadingIndicator != store.isLoading else { return }

        isAnimatingLoadingIndicator = true
        withAnimation(.easeInOut(duration: 0.4), completionCriteria: .removed) {
            showsLoadingIndicator = store.isLoading
        } completion: {
            isAnimatingLoadingIndicator = false
            updateLoadingIndicator()
        }
    }

    /// Keeps the number centered in the panel and grows the scrollable content in a short window.
    private struct ContentLayout: Layout {
        let viewportHeight: CGFloat
        let numberCenter: CGFloat

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let width = proposal.width ?? subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
            let arrangement = arrange(width: width, subviews: subviews)
            return CGSize(width: width, height: max(viewportHeight, arrangement.contentHeight))
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let arrangement = arrange(width: bounds.width, subviews: subviews)
            let textProposal = ProposedViewSize(width: bounds.width, height: nil)
            for (subview, topOffset) in zip(subviews, arrangement.topOffsets) {
                subview.place(
                    at: CGPoint(x: bounds.midX, y: bounds.minY + topOffset),
                    anchor: .top,
                    proposal: textProposal
                )
            }
        }

        private func arrange(width: CGFloat, subviews: Subviews) -> (topOffsets: [CGFloat], contentHeight: CGFloat) {
            let proposal = ProposedViewSize(width: width, height: nil)
            let heights = subviews.map { $0.sizeThatFits(proposal).height }
            let prefixTop = max(heights[0] + 16, numberCenter - heights[1] - heights[2] / 2)
            let numberTop = prefixTop + heights[1]
            let suffixTop = numberTop + heights[2]
            return ([0, prefixTop, numberTop, suffixTop], suffixTop + heights[3] + 16)
        }
    }
}
