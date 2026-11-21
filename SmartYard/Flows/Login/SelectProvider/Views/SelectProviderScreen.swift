//
//  SelectProviderScreen.swift
//  SmartYard
//
//  Created by Александр Попов on 21.11.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

struct SelectProviderScreen: View {
    @Bindable var store: SelectProviderStore

    @Environment(\.verticalSizeClass)
    private var verticalSizeClass
    @FocusState private var isSearchFocused: Bool
    @State private var showsLoadingIndicator = false
    @State private var isAnimatingLoadingIndicator = false

    private let twoColumnMinimumWidth: CGFloat = 680
    private let footerMaxWidth: CGFloat = 560
    private let listVerticalSpacing: CGFloat = 8

    private var usesCompactSpacing: Bool { verticalSizeClass == .compact }
    private var blocksInteraction: Bool { showsLoadingIndicator || isAnimatingLoadingIndicator }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: usesCompactSpacing ? 12 : 44)
                .contentShape(SwiftUI.Rectangle())
                .onTapGesture { isSearchFocused = false }
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                heading
                    .padding(.top, usesCompactSpacing ? 12 : 14)
                    .padding(.horizontal, 16)

                searchField
                    .padding(.top, usesCompactSpacing ? 18 : 20)
                    .padding(.horizontal, 16)

                GeometryReader { viewport in
                    let columnCount = viewport.size.width >= twoColumnMinimumWidth ? 2 : 1
                    ScrollView {
                        providers(columnCount: columnCount)
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .scrollBounceBehavior(.always)
                    .contentShape(SwiftUI.Rectangle())
                    .simultaneousGesture(TapGesture().onEnded { isSearchFocused = false })
                }
                .padding(.top, listVerticalSpacing)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { footer }
            .background {
                SYColor.secondBackground
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))
                    .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
                    .onTapGesture { isSearchFocused = false }
            }
        }
        .allowsHitTesting(!blocksInteraction)
        .accessibilityHidden(blocksInteraction)
        .overlay {
            ZStack {
                if showsLoadingIndicator {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                        .frame(width: 77, height: 77)
                        .background {
                            let card = RoundedRectangle(cornerRadius: 10)
                            // Match the tone of the dark UIKit HUD on this panel.
                            card.fill(.regularMaterial)
                                .overlay { card.fill(.white.opacity(0.035)) }
                        }
                        .environment(\.colorScheme, .dark)
                        .accessibilityIdentifier("provider.loading")
                        .transition(.opacity)
                }
            }
        }
        .onChange(of: store.isLoading, initial: true) { updateLoadingIndicator() }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .dynamicTypeSize(.large)
        .background {
            GeometryReader { geometry in
                Image("MainBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea()
        }
    }

    private func updateLoadingIndicator() {
        guard !isAnimatingLoadingIndicator, showsLoadingIndicator != store.isLoading else { return }

        // Complete the current fade before responding to a new loading state.
        isAnimatingLoadingIndicator = true
        withAnimation(.easeInOut(duration: 0.4), completionCriteria: .removed) {
            showsLoadingIndicator = store.isLoading
        } completion: {
            isAnimatingLoadingIndicator = false
            updateLoadingIndicator()
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: L10n.Auth.ProviderSelection.chooseAProvider)
                .font(SYFont.bold(size: 28))
                .accessibilityAddTraits(.isHeader)

            Text(verbatim: L10n.Auth.ProviderSelection.subtitle)
                .font(SYFont.regular(size: 14))
        }
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(SYColor.semiBlack)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(SwiftUI.Rectangle())
        .onTapGesture { isSearchFocused = false }
    }

    private var searchField: some View {
        TextField(
            "",
            text: $store.query,
            prompt: Text(verbatim: L10n.Auth.ProviderSelection.searchPlaceholder)
                .foregroundStyle(Color(uiColor: .placeholderText))
        )
        .font(SYFont.semibold(size: 18))
        .foregroundStyle(SYColor.semiBlack)
        .tint(SYColor.semiBlack)
        .textFieldStyle(.plain)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.sentences)
        .focused($isSearchFocused)
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(
            Color(uiColor: .SmartYard.grayBorder),
            in: RoundedRectangle(cornerRadius: 8, style: .circular)
        )
        .accessibilityLabel(Text(verbatim: L10n.Auth.ProviderSelection.searchPlaceholder))
        .accessibilityIdentifier("provider.search")
    }

    private func providers(columnCount: Int) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .top), count: columnCount)
        let providers = store.providers
        let lastRow = (providers.count - 1) / columnCount

        return LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(providers.enumerated()), id: \.element.provider.id) { index, item in
                SelectProviderRow(
                    item: item,
                    showsSeparator: index / columnCount < lastRow
                ) {
                    isSearchFocused = false
                    store.selectProvider(id: item.provider.id)
                }
            }
        }
    }

    private var footer: some View {
        Button {
            isSearchFocused = false
            store.continueToPhoneEntry()
        } label: {
            Text(verbatim: L10n.Common.next)
        }
        .buttonStyle(SYOutlineButtonStyle())
        .disabled(!store.canContinue)
        .accessibilityIdentifier("provider.next")
        .padding(.horizontal, 16)
        .frame(maxWidth: footerMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.top, listVerticalSpacing)
        .padding(.bottom, 8)
        .background(SYColor.secondBackground.ignoresSafeArea(.container, edges: [.horizontal, .bottom]))
    }
}
