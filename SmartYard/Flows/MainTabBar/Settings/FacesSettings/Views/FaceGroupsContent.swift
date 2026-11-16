//
//  Created by Александр Попов on 03.11.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI

private struct FaceRegistrationHelpIcon: UIViewRepresentable {
    func makeUIView(context: Context) -> CircleIconControl {
        let icon = CircleIconControl(frame: .zero)
        icon.apply(style: .Others.question)
        icon.isUserInteractionEnabled = false
        icon.isAccessibilityElement = false
        return icon
    }

    func updateUIView(_ uiView: CircleIconControl, context: Context) {}
}

struct FaceGroupsContent: View {
    let store: FacesSettingsStore
    let openGroupEditor: (FaceGroupEditor.Kind) -> Void
    @State private var deletingGroup: APIFaceGroup?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 0) {
                groupList
                    .frame(minWidth: 200, idealWidth: 220, maxWidth: 240)
                    .padding(.horizontal, 24)
                Color(uiColor: .SmartYard.grayBorder).frame(width: 1)
                facesPane(compact: false).frame(minWidth: 368, idealWidth: 408, maxWidth: .infinity)
            }
            facesPane(compact: true)
        }
        .font(SYFont.regular(size: 16))
        .tint(SYColor.blue)
        .alert(
            L10n.Settings.Faces.Groups.delete,
            isPresented: Binding(get: { deletingGroup != nil }, set: { if !$0 { deletingGroup = nil } })
        ) {
            Button(L10n.Common.delete, role: .destructive) {
                if let group = deletingGroup { store.deleteGroup(group) }
                deletingGroup = nil
            }
            Button(L10n.Common.cancel, role: .cancel) { deletingGroup = nil }
        } message: {
            Text(verbatim: L10n.Settings.Faces.Groups.deleteConfirmation(deletingGroup?.groupName ?? ""))
        }
    }

    private var groupList: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(L10n.Settings.Faces.Groups.title)
                .frame(minHeight: 44)
            HStack(spacing: 8) {
                groupRow(.all, title: L10n.Settings.Faces.Groups.all)
                groupControls
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    groupRow(.ungrouped, title: L10n.Settings.Faces.Groups.ungrouped)
                    ForEach(store.state.groups, id: \.groupId) { group in
                        groupRow(.group(group.groupId), title: group.groupName, group: group)
                    }
                }
            }
            .contentMargins(.bottom, 12, for: .scrollContent)
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .padding(.top, 16)
    }

    private var compactGroups: some View {
        HStack(spacing: 8) {
            Menu {
                Button(L10n.Settings.Faces.Groups.all) { store.selectGroup(.all) }
                    .accessibilityIdentifier("faces.filter.all")
                Button(L10n.Settings.Faces.Groups.ungrouped) { store.selectGroup(.ungrouped) }
                    .accessibilityIdentifier("faces.filter.ungrouped")
                ForEach(store.state.groups, id: \.groupId) { group in
                    Button { store.selectGroup(.group(group.groupId)) } label: {
                        Label(group.groupName, systemImage: store.trackingEnabled && group.watcherId != nil ? "eye" : "person.2")
                    }
                    .accessibilityIdentifier("faces.filter.group.\(group.groupId)")
                }
            } label: {
                HStack(spacing: 12) {
                    Text(verbatim: store.filterTitle)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SYColor.gray)
                }
                .foregroundStyle(SYColor.semiBlack)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color(uiColor: .SmartYard.backgroundColor), in: RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityIdentifier("faces.filter")
            if let group = store.selectedGroup { groupActions(group) }
            groupControls
        }
    }

    @ViewBuilder private var groupControls: some View {
        if store.canAddFace {
            Button(action: store.showRegistrationHelp) {
                FaceRegistrationHelpIcon()
                    .frame(width: 24, height: 24)
                    .frame(width: 44, height: 44)
                    .contentShape(SwiftUI.Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Settings.Faces.Groups.helpTitle)
            .accessibilityIdentifier("faces.help")
        }
        addGroup
    }

    private var addGroup: some View {
        Button { openGroupEditor(.create) } label: {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .contentShape(SwiftUI.Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(SYColor.blue)
        .accessibilityLabel(L10n.Settings.Faces.Groups.add)
        .accessibilityIdentifier("faces.groups.add")
    }

    private func groupRow(_ filter: FaceGroupFilter, title: String, group: APIFaceGroup? = nil) -> some View {
        HStack(spacing: 0) {
            Button { store.selectGroup(filter) } label: {
                HStack(spacing: 8) {
                    Text(verbatim: title)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if store.trackingEnabled, group?.watcherId != nil {
                        Image(systemName: "eye")
                            .font(.system(size: 14))
                            .accessibilityLabel(L10n.Settings.Faces.Groups.track)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .contentShape(SwiftUI.Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(uiColor: store.state.filter == filter ? .SmartYard.blue : .SmartYard.semiBlack))
            .accessibilityAddTraits(store.state.filter == filter ? .isSelected : [])
            .accessibilityIdentifier(filterIdentifier(filter))
            if let group, store.state.filter == filter { groupActions(group) }
        }
        .background(
            store.state.filter == filter ? Color(uiColor: .SmartYard.backgroundColor) : .clear,
            in: RoundedRectangle(cornerRadius: 10)
        )
    }

    private func groupActions(_ group: APIFaceGroup) -> some View {
        Menu {
            Button(L10n.Settings.Faces.Groups.edit, systemImage: "pencil") { openGroupEditor(.edit(group)) }
                .accessibilityIdentifier("faces.groups.edit")
            SYFaceTrackingToggle(person: group, store: store, accessibilityID: "faces.groups.tracking")
            Button(L10n.Settings.Faces.Groups.delete, systemImage: "trash", role: .destructive) {
                deletingGroup = group
            }
            .accessibilityIdentifier("faces.groups.delete")
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(SYColor.gray)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(L10n.Settings.Faces.Groups.actions)
        .accessibilityIdentifier("faces.groups.actions")
    }

    private func facesPane(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                facesHeader
                if compact { compactGroups }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 4)
            ScrollView { photoContent }
                .contentMargins(.horizontal, 24, for: .scrollContent)
                .contentMargins(.vertical, 12, for: .scrollContent)
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
                .accessibilityIdentifier("faces.grid")
            if store.clusteringEnabled && store.state.filter == .ungrouped {
                Button { openGroupEditor(.cluster) } label: {
                    Text(verbatim: L10n.Settings.Faces.Groups.cluster)
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(SYOutlineButtonStyle(font: SYFont.semibold(size: 16)))
                .disabled(!store.canCluster)
                .accessibilityIdentifier("faces.cluster")
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var facesHeader: some View {
        HStack(spacing: 8) {
            sectionTitle(L10n.Settings.Faces.registeredFaces)
            Spacer(minLength: 0)
            if store.canAddFace {
                Button(action: store.addFace) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .contentShape(SwiftUI.Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(SYColor.blue)
                .accessibilityLabel(L10n.Common.add)
                .accessibilityIdentifier("faces.add")
            }
        }
    }

    @ViewBuilder private var photoContent: some View {
        if store.hasReceivedFaces && store.visibleFaces.isEmpty {
            Text(verbatim: L10n.Settings.Faces.emptyStateMessage)
                .foregroundStyle(SYColor.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .padding(.vertical, 32)
                .accessibilityIdentifier("faces.empty")
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 112), spacing: 12, alignment: .top)], spacing: 24) {
                ForEach(store.visibleFaces, id: \.faceId) { face in
                    FaceGroupCard(face: face, store: store)
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(verbatim: title)
            .font(SYFont.semibold(size: 18))
            .foregroundStyle(SYColor.semiBlack)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private func filterIdentifier(_ filter: FaceGroupFilter) -> String {
        switch filter {
        case .all: return "faces.filter.all"
        case .ungrouped: return "faces.filter.ungrouped"
        case .group(let id): return "faces.filter.group.\(id)"
        }
    }
}
