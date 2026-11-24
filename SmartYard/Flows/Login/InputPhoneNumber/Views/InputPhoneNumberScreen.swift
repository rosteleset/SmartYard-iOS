//
//  InputPhoneNumberScreen.swift
//  SmartYard
//
//  Created by Александр Попов on 29.09.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

struct InputPhoneNumberScreen: View {
    @Bindable var store: InputPhoneNumberStore
    @FocusState private var isPhoneFocused: Bool
    @State private var draftPhoneNumber = ""
    @State private var showsLoadingIndicator = false
    @State private var isAnimatingLoadingIndicator = false

    // On iPad the system presents a keypad beside its insertion point.
    private let usesFloatingKeypad = UIDevice.current.userInterfaceIdiom == .pad

    var body: some View {
        GeometryReader { viewport in
            let narrowTablet = usesFloatingKeypad && viewport.size.width < 520
            let compact = usesFloatingKeypad && (viewport.size.height < 336 || narrowTablet)
            let roomy = viewport.size.width >= 620
            let windowControlsInset: CGFloat = narrowTablet ? 20 : 0
            let backBarHeight: CGFloat = usesFloatingKeypad ? (compact ? 44 : 68) + windowControlsInset : 69
            let panelHeight = max(0, viewport.size.height - backBarHeight)
            VStack(spacing: 0) {
                backBar(iconOnly: narrowTablet)
                    .padding(.top, windowControlsInset)
                    .frame(height: backBarHeight)
                panel(height: panelHeight, compact: compact, roomy: roomy)
            }
            .overlay {
                if usesFloatingKeypad {
                    phoneEditor
                        .position(x: viewport.size.width / 2, y: keypadAnchor(in: viewport.size.height))
                }
            }
            .allowsHitTesting(!blocksInteraction)
            .accessibilityHidden(blocksInteraction)
        }
        .overlay {
            ZStack {
                if showsLoadingIndicator {
                    loadingOverlay
                        .transition(.opacity)
                }
            }
        }
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
        .onAppear {
            draftPhoneNumber = store.phoneNumber
            isPhoneFocused = store.wantsKeyboard
        }
        .onChange(of: store.isLoading, initial: true) { updateLoadingIndicator() }
        .onChange(of: store.wantsKeyboard) { _, wantsKeyboard in
            isPhoneFocused = wantsKeyboard
        }
        .onChange(of: isPhoneFocused) { _, isFocused in
            store.wantsKeyboard = isFocused
        }
        .onChange(of: draftPhoneNumber) { oldValue, newValue in
            guard newValue.count <= store.digitGaps.count else {
                // Restore the editor buffer as well as the visible digits after an overlong edit.
                draftPhoneNumber = oldValue
                return
            }
            store.editPhoneNumber(newValue)
        }
        .onChange(of: store.phoneNumber) { _, phoneNumber in
            // Tapping a completed number clears it through beginEditing(), outside the editor.
            if draftPhoneNumber != phoneNumber {
                draftPhoneNumber = phoneNumber
            }
        }
        .dynamicTypeSize(.large)
    }

    private var blocksInteraction: Bool {
        store.isPreparingTransition || store.isLoading || showsLoadingIndicator || isAnimatingLoadingIndicator
    }

    private func updateLoadingIndicator() {
        guard !isAnimatingLoadingIndicator, showsLoadingIndicator != store.isLoading else { return }

        // Finish a pending fade before responding to another update from Rx.
        isAnimatingLoadingIndicator = true
        withAnimation(.easeInOut(duration: 0.4), completionCriteria: .removed) {
            showsLoadingIndicator = store.isLoading
        } completion: {
            isAnimatingLoadingIndicator = false
            updateLoadingIndicator()
        }
    }

    private func backBar(iconOnly: Bool) -> some View {
        HStack(spacing: 0) {
            Button(action: store.goBack) {
                HStack(spacing: 8) {
                    Image("BackArrowIcon")
                        .renderingMode(.template)
                    if !iconOnly {
                        Text(verbatim: L10n.Common.back)
                            .font(.system(size: 17))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(minWidth: iconOnly ? 44 : 152, maxHeight: .infinity, alignment: .leading)
                .contentShape(SwiftUI.Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(store.showsProviderControls ? 1 : 0)
            .allowsHitTesting(store.showsProviderControls)
            .accessibilityHidden(!store.showsProviderControls)
            .accessibilityLabel(Text(verbatim: L10n.Common.back))
            .accessibilityIdentifier("phone.back")
            Spacer(minLength: 0)
        }
        .background {
            Color.clear
                .contentShape(SwiftUI.Rectangle())
                .onTapGesture { store.wantsKeyboard = false }
        }
    }

    private func panel(height: CGFloat, compact: Bool, roomy: Bool) -> some View {
        ScrollView {
            phoneForm(compact: compact, roomy: roomy)
                .frame(maxWidth: .infinity)
                .frame(minHeight: height, alignment: .top)
                .background {
                    Color.clear
                        .contentShape(SwiftUI.Rectangle())
                        .onTapGesture { store.wantsKeyboard = false }
                }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.never)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 12,
                style: .circular
            )
            .fill(SYColor.secondBackground)
            .ignoresSafeArea(.all, edges: [.horizontal, .bottom])
        }
    }

    private func phoneForm(compact: Bool, roomy: Bool) -> some View {
        let minimumInputHeight: CGFloat = 44
        // Expand the hit target equally above and below the original 27 pt row.
        let inputHitInset = (minimumInputHeight - 27) / 2
        let providerAreaHeight: CGFloat = usesFloatingKeypad ? (compact ? 76 : 144) : 160 - inputHitInset
        let digitSize: CGFloat = usesFloatingKeypad ? (roomy ? 60 : 42) : 36
        let inputHeight: CGFloat = usesFloatingKeypad ? (roomy ? 80 : 56) : minimumInputHeight
        let inputInset: CGFloat = usesFloatingKeypad ? (roomy ? 24 : 8) : 5
        let hintSize: CGFloat = usesFloatingKeypad ? (roomy ? 24 : 17) : 13
        let hintTopInset: CGFloat = usesFloatingKeypad ? (compact ? 16 : 32) : 38 - inputHitInset

        return VStack(spacing: 0) {
            VStack(spacing: 0) {
                if store.showsProviderControls {
                    providerControls(compact: compact, roomy: roomy)
                        .padding(.top, compact ? 8 : 24)
                        .padding(.bottom, compact ? 8 : 16)
                }
            }
            .frame(minHeight: providerAreaHeight, alignment: .top)

            phoneInput(maximumFontSize: digitSize)
                .frame(height: inputHeight)
                .padding(.horizontal, inputInset)

            hint(font: SYFont.regular(size: hintSize))
                .frame(maxWidth: usesFloatingKeypad ? 480 : 203)
                .padding(.horizontal, 16)
                .padding(.top, hintTopInset)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: 620)
    }

    private func hint(font: Font) -> some View {
        Text(verbatim: L10n.Auth.PhoneEntry.title)
            .font(font)
            .foregroundStyle(SYColor.gray)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .onTapGesture { store.wantsKeyboard = false }
    }

    private func providerControls(compact: Bool, roomy: Bool) -> some View {
        let spacing: CGFloat = usesFloatingKeypad ? (compact ? 4 : 16) : 18
        let providerNameSize: CGFloat = usesFloatingKeypad ? (roomy ? 24 : 18) : 15
        let changeProviderSize: CGFloat = usesFloatingKeypad ? (roomy ? 20 : 16) : 13

        return VStack(spacing: spacing) {
            Text(verbatim: store.providerName)
                .font(SYFont.regular(size: providerNameSize))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .onTapGesture { store.wantsKeyboard = false }

            Button(action: store.changeProvider) {
                Text(verbatim: L10n.Auth.PhoneEntry.changeProviderButton)
                    .font(SYFont.regular(size: changeProviderSize))
                    .multilineTextAlignment(.center)
                    .frame(minHeight: usesFloatingKeypad ? 32 : 29)
                    .contentShape(SwiftUI.Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("phone.change-provider")
        }
        .foregroundStyle(SYColor.gray)
        .padding(.horizontal, 24)
    }

    private func phoneInput(maximumFontSize: CGFloat) -> some View {
        ZStack {
            if !usesFloatingKeypad {
                phoneEditor
            }

            InputPhoneNumberDigits(
                prefix: store.phonePrefix,
                digits: Array(store.phoneNumber),
                gaps: store.digitGaps,
                maximumFontSize: maximumFontSize
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .overlay {
            if usesFloatingKeypad {
                Button(action: focusPhoneInput) {
                    Color.clear.contentShape(SwiftUI.Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: L10n.Auth.PhoneEntry.title))
                .accessibilityValue(Text(verbatim: "+" + store.phonePrefix + store.phoneNumber))
                .accessibilityHidden(isPhoneFocused)
                .accessibilityIdentifier("phone.input-region")
            } else {
                Color.clear
                    .contentShape(SwiftUI.Rectangle())
                    .onTapGesture(perform: focusPhoneInput)
                    .accessibilityHidden(true)
            }
        }
    }

}

private extension InputPhoneNumberScreen {
    var phoneEditor: some View {
        TextField("", text: $draftPhoneNumber)
            .textFieldStyle(.plain)
            .keyboardType(.numberPad)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .foregroundStyle(.clear)
            .tint(.clear)
            .multilineTextAlignment(usesFloatingKeypad ? .center : .leading)
            .frame(maxWidth: usesFloatingKeypad ? 328 : .infinity)
            .focused($isPhoneFocused)
            .allowsHitTesting(false)
            .accessibilityLabel(Text(verbatim: L10n.Auth.PhoneEntry.title))
            .accessibilityValue(Text(verbatim: "+" + store.phonePrefix + store.phoneNumber))
            .accessibilityHidden(usesFloatingKeypad && !isPhoneFocused)
            .accessibilityIdentifier("phone.input")
    }

    func focusPhoneInput() {
        store.beginEditing()
        isPhoneFocused = true
    }

    func keypadAnchor(in height: CGFloat) -> CGFloat {
        // The popover opens above its native editor when there is space. A short
        // floating window leaves that space above the form, a tall window below it.
        height < 560 ? 14 : min(height - 72, 704)
    }

    var loadingOverlay: some View {
        ProgressView()
            .controlSize(.large)
            .tint(.white)
            .frame(width: 77, height: 77)
            .background {
                let card = RoundedRectangle(cornerRadius: 10)
                card.fill(.regularMaterial)
                    .overlay { card.fill(.white.opacity(0.035)) }
            }
            .environment(\.colorScheme, .dark)
            .accessibilityIdentifier("phone.loading")
    }
}
