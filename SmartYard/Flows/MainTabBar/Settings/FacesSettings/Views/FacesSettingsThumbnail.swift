//
//  Created by Александр Попов on 29.09.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

struct FacesSettingsAddButton: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                Image("plusSign")
                    .renderingMode(.template)
                    .foregroundStyle(SYColor.blue)
                    .frame(width: 52, height: 52)
                    .background(Color(uiColor: .SmartYard.backgroundColor), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: L10n.Common.add))
            .accessibilityIdentifier("faces.add")
            Spacer(minLength: 0)
        }
        .frame(width: 52, height: 92)
    }
}

struct FacesSettingsThumbnail: View {
    let face: APIFace
    let store: FacesSettingsStore

    var body: some View {
        VStack(spacing: 12) {
            Button { store.selectFace(face) } label: {
                ZStack {
                    Color(uiColor: .SmartYard.backgroundColor)
                    if let image = store.images[face.faceId] {
                        Image(uiImage: image)
                            .renderingMode(image.renderingMode == .alwaysTemplate ? .template : .original)
                            .resizable()
                            .frame(width: 52, height: 52)
                            .foregroundStyle(SYColor.blue)
                    } else if store.loadingImages.contains(face.faceId) {
                        ProgressView()
                            .tint(SYColor.gray)
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: L10n.Settings.Faces.registeredFaces))
            .accessibilityIdentifier("faces.image.\(face.faceId)")
            Button { store.deleteFace(face) } label: {
                Image("CloseRed")
                    .renderingMode(.original)
                    .frame(width: 28, height: 28)
                    .background(Color(uiColor: .SmartYard.grayBorder), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: L10n.Common.delete))
            .accessibilityIdentifier("faces.delete.\(face.faceId)")
        }
        .frame(width: 52, height: 92)
        .task(id: face.image) { await store.loadImage(for: face) }
    }
}
