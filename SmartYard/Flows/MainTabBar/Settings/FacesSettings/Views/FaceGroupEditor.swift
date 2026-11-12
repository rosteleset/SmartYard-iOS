//
//  Created by Александр Попов on 03.11.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

struct FaceGroupEditor: View {
    enum Kind: Identifiable {
        case create
        case edit(APIFaceGroup)
        case cluster

        var id: String {
            switch self {
            case .create: return "create"
            case .edit(let group): return "edit.\(group.groupId)"
            case .cluster: return "cluster"
            }
        }

        var title: String {
            switch self {
            case .create: return L10n.Settings.Faces.Groups.add
            case .edit: return L10n.Settings.Faces.Groups.edit
            case .cluster: return L10n.Settings.Faces.Groups.cluster
            }
        }

        var isClustering: Bool {
            if case .cluster = self { return true }
            return false
        }
    }

    let kind: Kind
    let store: FacesSettingsStore
    @State private var name: String
    @State private var isTracked: Bool
    @Environment(\.dismiss)
    private var dismiss

    init(kind: Kind, store: FacesSettingsStore) {
        self.kind = kind
        self.store = store
        if case .edit(let group) = kind {
            _name = State(initialValue: group.groupName)
            _isTracked = State(initialValue: group.watcherId != nil)
        } else {
            _name = State(initialValue: "")
            _isTracked = State(initialValue: false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(verbatim: kind.title)
                        .font(SYFont.semibold(size: 24))
                        .accessibilityAddTraits(.isHeader)
                    if kind.isClustering {
                        Text(verbatim: L10n.Settings.Faces.Groups.clusterHint)
                            .font(SYFont.regular(size: 14))
                            .foregroundStyle(SYColor.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: kind.isClustering ? L10n.Settings.Faces.Groups.prefix : L10n.Settings.Faces.Groups.name)
                            .font(SYFont.regular(size: 14))
                            .foregroundStyle(SYColor.gray)
                        TextField("", text: $name)
                            .font(SYFont.semibold(size: 18))
                            .textFieldStyle(.plain)
                            .frame(minHeight: 44)
                            .submitLabel(.done)
                            .onSubmit(save)
                            .accessibilityLabel(kind.isClustering ? L10n.Settings.Faces.Groups.prefix : L10n.Settings.Faces.Groups.name)
                            .accessibilityIdentifier("faces.group.name")
                        Color(uiColor: .SmartYard.grayBorder).frame(height: 1)
                    }
                    if store.trackingEnabled && !kind.isClustering {
                        Toggle(L10n.Settings.Faces.Groups.track, isOn: $isTracked)
                            .accessibilityIdentifier("faces.group.tracking")
                    }
                }
                .padding(24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button(action: save) {
                    Text(verbatim: kind.isClustering ? L10n.Settings.Faces.Groups.cluster : L10n.Common.save)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(SYPrimaryButtonStyle(height: 44))
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoading)
                .accessibilityIdentifier("faces.group.save")
                Button(L10n.Common.cancel, role: .cancel) { dismiss() }
                    .foregroundStyle(SYColor.blue)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("faces.group.cancel")
            }
            .padding(24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .background(SYColor.secondBackground)
        }
        .font(SYFont.regular(size: 16))
        .foregroundStyle(SYColor.semiBlack)
        .tint(SYColor.blue)
        .background(SYColor.secondBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !store.isLoading else { return }
        switch kind {
        case .create: store.createGroup(name: name, isTracked: isTracked)
        case .edit(let group): store.editGroup(group, name: name, isTracked: isTracked)
        case .cluster: store.cluster(prefix: name)
        }
        dismiss()
    }
}
