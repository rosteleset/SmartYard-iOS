//
//  UserNameScreen.swift
//  SmartYard
//
//  Created by Александр Попов on 26.11.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

private struct UserNameFieldStyle: ViewModifier {
    let isValid: Bool

    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(SYFont.regular(size: 18))
            .foregroundStyle(SYColor.semiBlack)
            .tint(SYColor.semiBlack)
            .textInputAutocapitalization(.words)
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(
                Color(uiColor: .SmartYard.grayBorder),
                in: RoundedRectangle(cornerRadius: 8, style: .circular)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .circular)
                    .strokeBorder(
                        isValid ? .clear : Color(uiColor: .SmartYard.incorrectDataRed),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            }
    }
}

/// Places the intrinsic form in the available area and lets short windows scroll.
private struct UserNameFormLayout: Layout {
    let viewportHeight: CGFloat
    let windowControlsInset: CGFloat
    let centersForm: Bool
    private let bottomInset: CGFloat = 36

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let form = subviews.first else { return .zero }
        let size = form.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
        return CGSize(width: proposal.width ?? size.width, height: topInset(for: size) + size.height + bottomInset)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let form = subviews.first else { return }
        let formProposal = ProposedViewSize(width: bounds.width, height: nil)
        let size = form.sizeThatFits(formProposal)
        form.place(
            at: CGPoint(x: bounds.midX, y: bounds.minY + topInset(for: size)),
            anchor: .top,
            proposal: formProposal
        )
    }

    private func topInset(for formSize: CGSize) -> CGFloat {
        let availableTopInset = viewportHeight - bottomInset - formSize.height
        let preferredTopInset = centersForm
            ? (windowControlsInset + availableTopInset) / 2
            : min(86, availableTopInset)
        return max(windowControlsInset, preferredTopInset)
    }
}

struct UserNameScreen: View {
    let store: UserNameStore

    @FocusState private var focusedField: Field?
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    private enum Field: Hashable {
        case firstName
        case middleName
    }

    var body: some View {
        GeometryReader { geometry in
            let usesIPadLayout = UIDevice.current.userInterfaceIdiom == .pad
            let narrowTablet = usesIPadLayout && geometry.size.width < 520
            ScrollView {
                UserNameFormLayout(
                    viewportHeight: geometry.size.height,
                    windowControlsInset: narrowTablet ? 28 : 0,
                    centersForm: usesIPadLayout
                ) {
                    VStack(spacing: 52) {
                        Text(verbatim: L10n.Auth.UserName.howCanICallYou)
                            .font(SYFont.bold(size: 32))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityAddTraits(.isHeader)
                            .onTapGesture { focusedField = nil }

                        formCard
                    }
                    .frame(maxWidth: 480)
                    .padding(.horizontal, horizontalSizeClass == .regular ? 32 : 16)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            .allowsHitTesting(!blocksInteraction)
            .accessibilityHidden(blocksInteraction)
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
            .background(SYColor.secondBackground)
            .ignoresSafeArea()
            .contentShape(SwiftUI.Rectangle())
            .onTapGesture { focusedField = nil }
        }
        .overlay {
            ZStack {
                if store.isLoading {
                    loadingOverlay.transition(.opacity)
                }
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: store.isLoading)
        }
        .dynamicTypeSize(.large)
        .onChange(of: store.isLoading) { _, isLoading in
            if isLoading { focusedField = nil }
        }
        .onChange(of: store.isPreparingTransition) { _, isPreparingTransition in
            if isPreparingTransition { focusedField = nil }
        }
        .onDisappear { focusedField = nil }
    }

    private var blocksInteraction: Bool {
        store.isLoading || store.isPreparingTransition
    }

    private var formCard: some View {
        VStack(spacing: 0) {
            TextField(
                "",
                text: Binding(get: { store.name }, set: store.editName),
                prompt: firstNamePlaceholder
            )
            .textContentType(.name)
            .submitLabel(.next)
            .focused($focusedField, equals: .firstName)
            .onSubmit { focusedField = .middleName }
            .modifier(UserNameFieldStyle(isValid: store.isNameValid))
            .accessibilityLabel(Text(verbatim: L10n.Profile.firstName))
            .accessibilityIdentifier("user-name.first-name")

            TextField(
                "",
                text: Binding(get: { store.middleName }, set: store.editMiddleName),
                prompt: Text(verbatim: L10n.Profile.patronymic).foregroundColor(placeholderColor)
            )
            .textContentType(.middleName)
            .submitLabel(.done)
            .focused($focusedField, equals: .middleName)
            .onSubmit { focusedField = nil }
            .modifier(UserNameFieldStyle(isValid: store.isMiddleNameValid))
            .accessibilityLabel(Text(verbatim: L10n.Profile.patronymic))
            .accessibilityIdentifier("user-name.middle-name")
            .padding(.top, 16)

            if let agreement = store.agreement {
                agreementRow(agreement)
                    .padding(.top, 24)
            }

            Button {
                focusedField = nil
                store.continueToMain()
            } label: {
                Text(verbatim: L10n.Common.next)
                    .opacity(store.isContinueEnabled ? 1 : 0.3)
            }
            .buttonStyle(SYPrimaryButtonStyle())
            .disabled(!store.isContinueEnabled)
            .accessibilityIdentifier("user-name.continue")
            .padding(.top, 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .circular)
                .fill(SYColor.secondBackground)
                .onTapGesture { focusedField = nil }
        }
    }

    private var placeholderColor: Color { SYColor.gray.opacity(0.4) }

    private var firstNamePlaceholder: Text {
        var placeholder = AttributedString(L10n.Profile.firstName)
        var requiredMark = AttributedString("*")
        requiredMark.baselineOffset = 3
        placeholder.append(requiredMark)
        return Text(placeholder).foregroundColor(placeholderColor)
    }

    private func agreementRow(_ caption: NSAttributedString) -> some View {
        HStack(spacing: 10) {
            Button {
                focusedField = nil
                store.toggleAgreement()
            } label: {
                ZStack {
                    Image("CheckBoxBorder")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                    if store.isAgreementAccepted {
                        Image("CheckIcon")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 11)
                    }
                }
                .foregroundStyle(SYColor.blue)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: NSLocalizedString(
                "auth.userName.agreement.accessibilityLabel",
                comment: ""
            )))
            .accessibilityAddTraits(store.isAgreementAccepted ? [.isSelected] : [])
            .accessibilityIdentifier("user-name.agreement")

            UserNameAgreementText(caption: caption) { url in
                focusedField = nil
                store.openLegalDocument(url)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.clear
                .contentShape(SwiftUI.Rectangle())
                .onTapGesture {}

            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)
                .tint(.white)
                .frame(width: 77, height: 77)
                .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityIdentifier("user-name.loading")
        }
    }
}
