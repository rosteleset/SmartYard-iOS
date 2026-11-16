//
//  Created by Александр Попов on 03.11.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

struct SYFaceTrackingToggle: View {
    let person: APIFaceGroup
    let store: FacesSettingsStore
    let accessibilityID: String

    var body: some View {
        if store.trackingEnabled {
            Toggle(isOn: Binding(
                get: { person.watcherId != nil },
                set: { store.setTracking($0, for: person.groupId) }
            )) {
                Label(L10n.Settings.Faces.Groups.track, systemImage: "bell")
            }
            .disabled(store.isLoading)
            .accessibilityIdentifier(accessibilityID)
        }
    }
}

struct FaceGroupCard: View {
    let face: APIFace
    let store: FacesSettingsStore

    private var person: APIFaceGroup? {
        store.state.groups.first { $0.groupId == face.groupId }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Button { store.selectFace(face) } label: {
                    ZStack {
                        SYColor.gray.opacity(0.2)
                        if let image = store.images[face.faceId] {
                            Image(uiImage: image).resizable().scaledToFill()
                        } else if store.loadingImages.contains(face.faceId) {
                            ProgressView().tint(SYColor.gray)
                        } else {
                            Image("DefaultUserIcon")
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.Settings.Faces.registeredFaces)
                .accessibilityIdentifier("faces.image.\(face.faceId)")
                actions
                    .alignmentGuide(.bottom) { $0[.bottom] - 8 }
                    .alignmentGuide(.trailing) { $0[.trailing] - 8 }
            }
            .padding(8)
            if store.state.filter == .all {
                Text(verbatim: person?.groupName ?? L10n.Settings.Faces.Groups.ungrouped)
                    .font(SYFont.regular(size: 13))
                    .foregroundStyle(SYColor.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .task(id: face.image) { await store.loadImage(for: face) }
    }

    private var actions: some View {
        Menu {
            if face.groupId == nil, !store.state.groups.isEmpty {
                Section(L10n.Settings.Faces.Groups.move) {
                    ForEach(store.state.groups, id: \.groupId) { group in
                        Button(group.groupName) { store.moveFace(face, to: group) }
                            .accessibilityIdentifier("faces.move.\(face.faceId).\(group.groupId)")
                    }
                }
            }
            if let person {
                SYFaceTrackingToggle(person: person, store: store, accessibilityID: "faces.tracking.\(face.faceId)")
            }
            if face.groupId != nil {
                Button(L10n.Settings.Faces.Groups.detach, systemImage: "link") { store.detachFace(face) }
                    .accessibilityIdentifier("faces.detach.\(face.faceId)")
            }
            Button(L10n.Common.delete, systemImage: "trash", role: .destructive) { store.deleteFace(face) }
                .accessibilityIdentifier("faces.delete.\(face.faceId)")
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SYColor.gray)
                .frame(width: 28, height: 28)
                .background(SYColor.secondBackground, in: Circle())
                .overlay { Circle().strokeBorder(Color(uiColor: .SmartYard.grayBorder), lineWidth: 1) }
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .accessibilityLabel(L10n.Settings.Faces.Groups.faceActions)
        .accessibilityIdentifier("faces.membership.\(face.faceId)")
    }
}
