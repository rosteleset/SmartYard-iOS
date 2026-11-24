//
//  PinCodeScreen.swift
//  SmartYard
//
//  Created by Александр Попов on 29.09.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

struct PinCodeScreen: View {
    @Bindable var store: PinCodeStore
    let useFlashCall: Bool

    @FocusState private var isPinFocused: Bool
    @State private var draftPin = ""
    @State private var showsLoadingIndicator = false
    @State private var isAnimatingLoadingIndicator = false

    // The iPad number pad is a system popover anchored to the editor.
    private let usesFloatingKeypad = UIDevice.current.userInterfaceIdiom == .pad
    private let legacyHintColor = Color(red: 109.0 / 255, green: 122.0 / 255, blue: 138.0 / 255)

    var body: some View {
        GeometryReader { viewport in
            let narrowTablet = usesFloatingKeypad && viewport.size.width < 520
            let compact = usesFloatingKeypad && (viewport.size.height < 336 || narrowTablet)
            let roomy = viewport.size.width >= 620
            let windowControlsInset: CGFloat = narrowTablet ? 20 : 0
            let backBarHeight: CGFloat = usesFloatingKeypad ? (compact ? 44 : 68) + windowControlsInset : 69
            VStack(spacing: 0) {
                backBar(iconOnly: narrowTablet)
                    .padding(.top, windowControlsInset)
                    .frame(height: backBarHeight)
                panel(compact: compact, roomy: roomy)
            }
            .overlay {
                if usesFloatingKeypad {
                    pinEditor
                        .position(x: viewport.size.width / 2, y: keypadAnchor(in: viewport.size.height))
                }
            }
            .allowsHitTesting(!blocksInteraction)
            .accessibilityHidden(blocksInteraction)
        }
        .overlay {
            ZStack {
                if showsLoadingIndicator {
                    loadingOverlay.transition(.opacity)
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
            draftPin = store.pin
            isPinFocused = store.wantsKeyboard
        }
        .onChange(of: store.isLoading, initial: true) { updateLoadingIndicator() }
        .onChange(of: store.wantsKeyboard) { _, wantsKeyboard in
            isPinFocused = wantsKeyboard
        }
        .onChange(of: isPinFocused) { _, isFocused in
            store.wantsKeyboard = isFocused
        }
        .onChange(of: draftPin) { oldValue, newValue in
            guard newValue.count <= Constants.pinLength else {
                draftPin = oldValue
                return
            }
            store.editPin(newValue)
        }
        .dynamicTypeSize(.large)
    }

    private var blocksInteraction: Bool {
        store.isPreparingTransition || store.isLoading || showsLoadingIndicator || isAnimatingLoadingIndicator
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
            .accessibilityIdentifier("pin.back")

            Spacer(minLength: 0)
        }
        .background { dismissKeyboardArea }
    }

    private func panel(compact: Bool, roomy: Bool) -> some View {
        VStack(spacing: 0) {
            GeometryReader { viewport in
                ScrollView {
                    pinForm(compact: compact, roomy: roomy)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: viewport.size.height, alignment: .top)
                        .background { dismissKeyboardArea }
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.never)
            }

            resendControls(roomy: roomy)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 28)
        }
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12)
                .fill(SYColor.secondBackground)
                .ignoresSafeArea(.all, edges: [.horizontal, .bottom])
        }
    }

    private func pinForm(compact: Bool, roomy: Bool) -> some View {
        let hintSize: CGFloat = usesFloatingKeypad ? (roomy ? 24 : 17) : 13
        let fixPhoneTopInset: CGFloat = usesFloatingKeypad ? (compact ? 12 : 28) : 28.5

        return VStack(spacing: 0) {
            phoneHint(font: SYFont.regular(size: hintSize))
                .padding(.horizontal, 24)

            fixPhoneButton(roomy: roomy)
                .padding(.top, fixPhoneTopInset)

            pinInput(maximumFontSize: roomy ? 72 : 48)
                .frame(height: roomy ? 100 : 80)
                .padding(.horizontal, usesFloatingKeypad ? 4 : 5)
                .padding(.top, compact ? 8 : 20)

            if !store.isPinCorrect {
                invalidCode(roomy: roomy).padding(.top, 14)
            }
        }
        .padding(.top, compact ? 16 : 36)
        .padding(.bottom, 20)
        .frame(maxWidth: 620)
    }

    private func phoneHint(font: Font) -> some View {
        Text(verbatim: store.phoneHint)
            .font(font)
            .foregroundStyle(SYColor.gray)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .onTapGesture { store.wantsKeyboard = false }
    }

    private func fixPhoneButton(roomy: Bool) -> some View {
        let fontSize: CGFloat = usesFloatingKeypad ? (roomy ? 20 : 17) : 15

        return Button(action: store.fixPhoneNumber) {
            Text(verbatim: L10n.Auth.CallVerification.editPhoneButton)
                .font(.system(size: fontSize))
                .foregroundStyle(usesFloatingKeypad ? SYColor.gray : legacyHintColor.opacity(0.5))
                .multilineTextAlignment(.center)
                .frame(minHeight: usesFloatingKeypad ? 32 : 30)
                .contentShape(SwiftUI.Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pin.fix-phone")
    }

    private func pinInput(maximumFontSize: CGFloat) -> some View {
        ZStack {
            if !usesFloatingKeypad {
                pinEditor
            }

            PinCodeDigits(digits: Array(store.pin), isCorrect: store.isPinCorrect, maximumFontSize: maximumFontSize)
                .allowsHitTesting(false)
        }
        .overlay {
            if usesFloatingKeypad {
                Button(action: focusPinInput) {
                    Color.clear.contentShape(SwiftUI.Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: store.phoneHint))
                .accessibilityValue(Text(verbatim: store.pin))
                .accessibilityHidden(isPinFocused)
                .accessibilityIdentifier("pin.input-region")
            } else {
                Color.clear
                    .contentShape(SwiftUI.Rectangle())
                    .onTapGesture(perform: focusPinInput)
                    .accessibilityHidden(true)
            }
        }
    }

    private var pinEditor: some View {
        TextField("", text: $draftPin)
            .textFieldStyle(.plain)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundStyle(.clear)
            .tint(.clear)
            .multilineTextAlignment(usesFloatingKeypad ? .center : .leading)
            .frame(maxWidth: usesFloatingKeypad ? 240 : .infinity)
            .focused($isPinFocused)
            .allowsHitTesting(false)
            .accessibilityLabel(Text(verbatim: store.phoneHint))
            .accessibilityHidden(usesFloatingKeypad && !isPinFocused)
            .accessibilityIdentifier("pin.input")
    }

    private func focusPinInput() {
        store.wantsKeyboard = true
        isPinFocused = true
    }

    private func keypadAnchor(in height: CGFloat) -> CGFloat {
        // Keep the floating popover in free space, above the bottom resend area.
        height < 560 ? 14 : min(height - 104, 704)
    }

    private func invalidCode(roomy: Bool) -> some View {
        let fontSize: CGFloat = usesFloatingKeypad ? (roomy ? 18 : 15) : 13

        return Text(verbatim: L10n.Auth.Pin.invalidCode)
            .font(.system(size: fontSize))
            .foregroundStyle(Color(uiColor: .SmartYard.incorrectDataRed))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .accessibilityIdentifier("pin.error")
    }
}

private extension PinCodeScreen {
    func resendControls(roomy: Bool) -> some View {
        let buttonFontSize: CGFloat = usesFloatingKeypad ? (roomy ? 20 : 17) : 15
        let countdownFontSize: CGFloat = usesFloatingKeypad ? (roomy ? 20 : 16) : 13

        return Group {
            if store.isResendAvailable {
                Button(action: store.resendCode) {
                    Text(verbatim: useFlashCall
                        ? L10n.Auth.FlashCall.resendButton
                        : L10n.Auth.PasswordRecovery.Code.resendButton)
                        .foregroundStyle(.white)
                }
                .buttonStyle(SYPrimaryButtonStyle(font: .system(size: buttonFontSize)))
                .padding(.horizontal, usesFloatingKeypad ? 16 : 40)
                .accessibilityIdentifier("pin.resend")
            } else {
                VStack(spacing: usesFloatingKeypad ? 4 : 3) {
                    Text(verbatim: useFlashCall ? L10n.Auth.FlashCall.resendHint : L10n.Auth.SMSCode.resendHint)
                    Text(verbatim: store.countdownText)
                        .accessibilityIdentifier("pin.countdown")
                }
                .font(SYFont.regular(size: countdownFontSize))
                .foregroundStyle(legacyHintColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
                .onTapGesture { store.wantsKeyboard = false }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background { dismissKeyboardArea }
    }

    var dismissKeyboardArea: some View {
        Color.clear
            .contentShape(SwiftUI.Rectangle())
            .onTapGesture { store.wantsKeyboard = false }
            .accessibilityHidden(true)
    }

    var loadingOverlay: some View {
        ProgressView()
            .controlSize(.large)
            .tint(.white)
            .frame(width: 77, height: 77)
            .background {
                let card = RoundedRectangle(cornerRadius: 10)
                card.fill(.regularMaterial).overlay { card.fill(.white.opacity(0.035)) }
            }
            .environment(\.colorScheme, .dark)
            .accessibilityIdentifier("pin.loading")
    }
}
