//
//  Created by Александр Попов on 03.11.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import SwiftUI
import SnapKit

final class FaceGroupEditorViewController: UIViewController {
    private let kind: FaceGroupEditor.Kind
    private let store: FacesSettingsStore
    private let card = FullRoundedView()
    private let scrollView = UIScrollView()

    init(kind: FaceGroupEditor.Kind, store: FacesSettingsStore) {
        self.kind = kind
        self.store = store
        super.init(nibName: nil, bundle: nil)
        SYFormModal.configurePresentation(of: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }

    private func setupUI() {
        card.backgroundColor = .SmartYard.secondBackgroundColor
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive
        view.accessibilityViewIsModal = true
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissIfOutsideCard))
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)
    }

    private func setupConstraints() {
        let form = UIHostingController(rootView: FaceGroupEditor(kind: kind, store: store) { [weak self] in
            self?.dismiss(animated: true)
        })
        form.safeAreaRegions = []
        form.sizingOptions = .intrinsicContentSize
        form.view.backgroundColor = .clear

        addChild(form)
        SYFormModal.place(card, in: view)
        card.pinSubview(scrollView)
        scrollView.addSubview(form.view) { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide.snp.width)
        }
        scrollView.snp.makeConstraints { $0.height.equalTo(form.view.snp.height).priority(249) }
        form.didMove(toParent: self)
    }

    @objc private func dismissIfOutsideCard(_ tap: UITapGestureRecognizer) {
        guard !card.bounds.contains(tap.location(in: card)) else { return }
        dismiss(animated: true)
    }
}

struct FaceGroupEditor: View {
    enum Kind {
        case create
        case edit(APIFaceGroup)
        case cluster

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
    let close: () -> Void
    @State private var name: String
    @State private var isTracked: Bool

    init(kind: Kind, store: FacesSettingsStore, close: @escaping () -> Void) {
        self.kind = kind
        self.store = store
        self.close = close
        if case .edit(let group) = kind {
            _name = State(initialValue: group.groupName)
            _isTracked = State(initialValue: group.watcherId != nil)
        } else {
            _name = State(initialValue: "")
            _isTracked = State(initialValue: false)
        }
    }

    var body: some View {
        let insets = SYFormModal.contentInsets
        VStack(alignment: .leading, spacing: SYFormModal.sectionSpacing) {
            Text(verbatim: kind.title)
                .font(SYFont.bold(size: SYFormModal.titleSize))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if kind.isClustering {
                Text(verbatim: L10n.Settings.Faces.Groups.clusterHint)
                    .font(SYFont.regular(size: 14))
                    .fixedSize(horizontal: false, vertical: true)
            }
            nameField
            if store.trackingEnabled && !kind.isClustering {
                trackingOption
            }
            Button(action: save) {
                Text(verbatim: kind.isClustering ? L10n.Settings.Faces.Groups.cluster : L10n.Common.save)
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(SYPrimaryButtonStyle(height: SYFormModal.buttonHeight))
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoading)
            .accessibilityIdentifier("faces.group.save")
        }
        .padding(.init(top: insets.top, leading: insets.leading, bottom: insets.bottom, trailing: insets.trailing))
        .foregroundStyle(SYColor.semiBlack)
        .tint(SYColor.blue)
        .accessibilityAction(.escape, close)
    }

    private var nameField: some View {
        let label = kind.isClustering ? L10n.Settings.Faces.Groups.prefix : L10n.Settings.Faces.Groups.name
        return VStack(alignment: .leading, spacing: 8) {
            TextField(label, text: $name, prompt: Text(verbatim: label).foregroundStyle(SYColor.gray))
                .font(SYFont.semibold(size: 18))
                .textFieldStyle(.plain)
                .frame(minHeight: 44)
                .submitLabel(.done)
                .onSubmit(save)
                .accessibilityIdentifier("faces.group.name")
            Color(uiColor: .SmartYard.grayBorder)
                .frame(height: 1)
                .accessibilityHidden(true)
            if !kind.isClustering {
                Text(verbatim: L10n.Settings.Faces.Groups.personHint)
                    .font(SYFont.regular(size: 14))
                    .foregroundStyle(SYColor.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var trackingOption: some View {
        let title = L10n.Settings.Faces.Groups.track
        return HStack(spacing: 12) {
            Text(verbatim: title)
                .font(SYFont.regular(size: 18))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)
            Toggle(title, isOn: $isTracked)
                .labelsHidden()
                .toggleStyle(.switch)
                .fixedSize()
                .tint(Color(uiColor: .SmartYard.darkGreen))
                .accessibilityIdentifier("faces.group.tracking")
        }
        .padding(.vertical, 4)
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !store.isLoading else { return }
        switch kind {
        case .create: store.createGroup(name: name, isTracked: isTracked)
        case .edit(let group): store.editGroup(group, name: name, isTracked: isTracked)
        case .cluster: store.cluster(prefix: name)
        }
        close()
    }
}
