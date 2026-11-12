//
//  Created by Александр Попов on 29.09.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

private struct FacesSettingsBackBar: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image("BackArrowIcon").renderingMode(.template)
                Text(verbatim: L10n.Common.back)
                    .font(.system(size: 17))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .contentShape(SwiftUI.Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FacesSettingsBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Image("MainBackground")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct FacesSettingsCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(SYColor.secondBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(uiColor: .SmartYard.grayBorder), lineWidth: 1)
                    .allowsHitTesting(false)
            }
    }
}

struct FacesSettingsScreen: View {
    let store: FacesSettingsStore
    var openGroupEditor: (FaceGroupEditor.Kind) -> Void = { _ in }
    @State private var showsLoadError = false
    @State private var retriesAfterDismissal = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                FacesSettingsBackBar(action: store.goBack)
                Text(verbatim: store.groupsEnabled ? L10n.Settings.Faces.Groups.screenTitle : L10n.Settings.Faces.faceRegistration)
                    .font(SYFont.bold(size: 32))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 1100, alignment: .leading)
                    .frame(maxWidth: .infinity)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 19)
                ZStack(alignment: .top) {
                    UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24, style: .circular)
                        .fill(Color(uiColor: .SmartYard.backgroundColor))
                        .padding(.top, 35)
                        .ignoresSafeArea(.container, edges: .bottom)
                    Group {
                        if store.groupsEnabled {
                            FacesSettingsCard {
                                FaceGroupsContent(store: store, openGroupEditor: openGroupEditor)
                            }
                        } else {
                            contentCard
                        }
                    }
                    .frame(maxWidth: 1100)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 11)
                    .allowsHitTesting(!store.isLoading)
                }
            }
            if store.isLoading {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                    .frame(width: 77, height: 77)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .environment(\.colorScheme, .dark)
                    .allowsHitTesting(false)
            }
        }
        .background { FacesSettingsBackground() }
        .onChange(of: store.loadError, initial: true) { _, error in
            if error != nil { showsLoadError = true }
        }
        .alert(L10n.Common.error, isPresented: $showsLoadError, presenting: store.loadError) { _ in
            Button(L10n.Settings.Faces.Groups.retry) { retriesAfterDismissal = true }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: { error in
            Text(verbatim: error.message)
        }
        .onChange(of: showsLoadError) { _, isShowing in
            guard !isShowing else { return }
            store.dismissLoadError()
            guard retriesAfterDismissal else { return }
            retriesAfterDismissal = false
            store.refresh()
        }
    }

    private var contentCard: some View {
        FacesSettingsCard {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(verbatim: L10n.Settings.Faces.registeredFaces)
                        .font(SYFont.semibold(size: 18))
                        .foregroundStyle(SYColor.semiBlack)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .accessibilityAddTraits(.isHeader)
                    faceCollection
                    if store.canAddFace {
                        Text(verbatim: L10n.Settings.Faces.registrationHint)
                            .font(SYFont.regular(size: 14))
                            .foregroundStyle(SYColor.semiBlack)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 24)
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        }
    }

    private var faceCollection: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                if store.canAddFace { FacesSettingsAddButton(action: store.addFace) }
                ForEach(store.faces, id: \.faceId) { face in
                    FacesSettingsThumbnail(face: face, store: store)
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 92)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .scrollTargetBehavior(.paging)
        .overlay {
            if store.hasReceivedFaces && store.faces.isEmpty {
                Text(verbatim: L10n.Settings.Faces.emptyStateMessage)
                    .font(SYFont.semibold(size: 18))
                    .foregroundStyle(SYColor.gray)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, store.canAddFace ? 88 : 32)
                    .padding(.trailing, 16)
                    .allowsHitTesting(false)
            }
        }
    }
}
