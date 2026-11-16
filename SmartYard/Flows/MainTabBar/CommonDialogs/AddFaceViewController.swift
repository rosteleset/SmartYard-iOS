//
//  AddFaceViewController.swift
//  SmartYard
//
//  Created by Александр Васильев on 13.05.2021.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import UIKit
import JGProgressHUD
import RxSwift
import SnapKit

final class AddFaceViewController: BaseViewController, LoaderPresentable {
    var loader: JGProgressHUD?

    private let event: APIPlog
    private let apiWrapper: APIWrapper
    private let workflow: FaceRegistrationWorkflow?

    private let card = FullRoundedView()
    private let scrollView = UIScrollView()
    private let titleLabel = UILabel()
    private let preview = SafeCachedImageView()
    private let personLabel = UILabel()
    private let personButton = UIButton(type: .system)
    private let nameField = UITextField()
    private let nameDivider = UIView()
    private let nameHint = UILabel()
    private let addButton = BlueButton(frame: .zero)
    private let cancelButton = UIButton(type: .system)

    private var selection: FaceRegistrationWorkflow.Selection = .ungrouped
    private var people: [APIFaceGroup] = []
    private var peopleLoadFailed = false
    private var isSaving = false

    init(apiWrapper: APIWrapper, event: APIPlog) {
        self.apiWrapper = apiWrapper
        self.event = event
        if let flatId = event.flatId, flatId > 0, apiWrapper.accessService.faceGroupsEnabled {
            workflow = apiWrapper.faceRegistrationWorkflow(eventId: event.uuid, flatId: flatId)
        } else {
            workflow = nil
        }
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindKeyboard()
        updatePersonControls()
        loadPreview()
        loadPeople()
    }

    override func accessibilityPerformEscape() -> Bool {
        guard !isSaving else { return false }
        close()
        return true
    }
}

private extension AddFaceViewController {
    func setupUI() {
        view.accessibilityViewIsModal = true
        card.backgroundColor = .SmartYard.secondBackgroundColor
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive

        titleLabel.text = L10n.FaceRecognition.AddFace.addThisFace
        titleLabel.textColor = .SmartYard.semiBlack
        titleLabel.font = .SourceSansPro.bold(size: SYFormModal.titleSize)
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits.insert(.header)

        preview.backgroundColor = .SmartYard.backgroundColor
        preview.contentMode = .scaleAspectFit
        preview.layer.cornerRadius = 12
        preview.clipsToBounds = true

        personLabel.text = L10n.Settings.Faces.Groups.person
        personLabel.textColor = .SmartYard.semiBlack
        personLabel.font = .SourceSansPro.semibold(size: 16)
        personLabel.numberOfLines = 0
        personLabel.isAccessibilityElement = false
        personButton.showsMenuAsPrimaryAction = true
        personButton.contentHorizontalAlignment = .fill
        personButton.accessibilityLabel = L10n.Settings.Faces.Groups.person
        personButton.accessibilityIdentifier = "faces.registration.person"

        nameField.attributedPlaceholder = NSAttributedString(
            string: L10n.Settings.Faces.Groups.name,
            attributes: [.foregroundColor: UIColor.SmartYard.gray]
        )
        nameField.font = .SourceSansPro.semibold(size: 18)
        nameField.textColor = .SmartYard.semiBlack
        nameField.autocapitalizationType = .words
        nameField.returnKeyType = .done
        nameField.accessibilityIdentifier = "faces.registration.name"
        nameField.addTarget(self, action: #selector(nameDidChange), for: .editingChanged)
        nameField.addTarget(self, action: #selector(save), for: .editingDidEndOnExit)

        nameHint.text = L10n.Settings.Faces.Groups.personHint
        nameHint.font = .SourceSansPro.regular(size: 14)
        nameHint.textColor = .SmartYard.gray
        nameHint.numberOfLines = 0

        addButton.titleLabel?.font = .SourceSansPro.semibold(size: 18)
        addButton.accessibilityIdentifier = "faces.registration.add"
        addButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        cancelButton.setTitle(L10n.Common.cancel, for: .normal)
        cancelButton.setTitleColor(.SmartYard.blue, for: .normal)
        cancelButton.titleLabel?.font = .SourceSansPro.regular(size: 18)
        cancelButton.accessibilityIdentifier = "faces.registration.cancel"
        cancelButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissIfOutsideCard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    func setupConstraints() {
        let form = UIStackView.vertical(paddings: SYFormModal.contentInsets, spacing: SYFormModal.sectionSpacing)
        nameDivider.backgroundColor = .SmartYard.grayBorder
        let personField = UIStackView.vertical(spacing: 8)
        personField.add {
            personLabel
            personButton
            nameField
            nameDivider
            nameHint
        }
        personField.isHidden = workflow == nil

        let actions = UIStackView.vertical(spacing: 4)
        actions.add {
            addButton
            cancelButton
        }
        form.add {
            titleLabel
            preview
            personField
            actions
        }
        SYFormModal.place(card, in: view)
        card.pinSubview(scrollView)
        scrollView.addSubview(form) { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide.snp.width)
        }
        scrollView.snp.makeConstraints { $0.height.equalTo(form.snp.height).priority(249) }
        preview.snp.makeConstraints { $0.height.equalTo(preview.snp.width).multipliedBy(9.0 / 16).priority(999) }
        personButton.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44).priority(999) }
        nameField.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44).priority(999) }
        nameDivider.snp.makeConstraints { $0.height.equalTo(1).priority(999) }
        addButton.snp.makeConstraints { $0.height.equalTo(SYFormModal.buttonHeight) }
        cancelButton.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
    }

    func bindKeyboard() {
        NotificationCenter.default.rx.notification(UIResponder.keyboardDidShowNotification)
            .subscribe(with: self) { owner, _ in
                guard owner.nameField.isFirstResponder else { return }
                let field = owner.nameField.convert(owner.nameField.bounds, to: owner.scrollView)
                owner.scrollView.scrollRectToVisible(field.insetBy(dx: 0, dy: -8), animated: true)
            }
            .disposed(by: disposeBag)
    }

    func loadPreview() {
        let rect = event.detailX?.face?.asCGRect
        if let image = event.previewImage {
            preview.image = image
            if let rect { preview.drawRectangle(rect: rect, rectColor: .red) }
        } else if let url = event.previewURL, !url.isEmpty {
            preview.loadImageUsingUrlString(urlString: url, cache: imagesCache, rect: rect, rectColor: .red)
        } else {
            preview.isHidden = true
        }
    }

}

private extension AddFaceViewController {
    func loadPeople() {
        guard workflow != nil, let flatId = event.flatId else { return }
        apiWrapper.getFaceGroups(flatId: flatId)
            .observe(on: MainScheduler.instance)
            .subscribe(
                with: self,
                onSuccess: { owner, people in
                    owner.people = people
                    owner.peopleLoadFailed = false
                    owner.updatePersonControls()
                },
                onFailure: { owner, _ in
                    owner.peopleLoadFailed = true
                    owner.updatePersonControls()
                }
            )
            .disposed(by: disposeBag)
    }

    func updatePersonControls() {
        let title: String
        let isNewPerson: Bool
        switch selection {
        case .ungrouped:
            title = L10n.Settings.Faces.Groups.ungrouped
            isNewPerson = false
        case .existing(let person):
            title = person.groupName
            isNewPerson = false
        case .new:
            title = L10n.Settings.Faces.Groups.add
            isNewPerson = true
        }
        var configuration = UIButton.Configuration.plain()
        configuration.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: UIFont.SourceSansPro.regular(size: 18)
        ]))
        configuration.image = UIImage(
            systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        )
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 12
        configuration.titleAlignment = .leading
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.baseForegroundColor = .SmartYard.semiBlack
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = 10
        configuration.background.backgroundColor = .SmartYard.backgroundColor
        configuration.contentInsets = .init(top: 10, leading: 12, bottom: 10, trailing: 12)
        personButton.configuration = configuration
        personButton.accessibilityValue = title
        updatePersonMenu()
        nameField.isHidden = !isNewPerson
        nameDivider.isHidden = !isNewPerson
        nameHint.isHidden = !isNewPerson
        nameDidChange()
    }

    func updatePersonMenu() {
        let unnamedAction = personAction(L10n.Settings.Faces.Groups.ungrouped, selection: .ungrouped)
        let existingActions = people.map { personAction($0.groupName, selection: .existing($0)) }
        let addPerson = personAction(L10n.Settings.Faces.Groups.add, selection: .new(""), image: UIImage(systemName: "person.badge.plus"))
        var actions = [unnamedAction] + existingActions + [addPerson]
        if peopleLoadFailed {
            actions.append(UIAction(title: L10n.Settings.Faces.Groups.retry, image: UIImage(systemName: "arrow.clockwise")) { [weak self] _ in
                self?.loadPeople()
            })
        }
        personButton.menu = UIMenu(children: actions)
    }

    func personAction(
        _ title: String,
        selection: FaceRegistrationWorkflow.Selection,
        image: UIImage? = nil
    ) -> UIAction {
        UIAction(title: title, image: image, state: self.selection == selection ? .on : .off) { [weak self] _ in
            guard let self, !isSaving else { return }
            self.selection = selection
            updatePersonControls()
            if case .new = selection {
                nameField.becomeFirstResponder()
            } else {
                nameField.resignFirstResponder()
            }
        }
    }

    @objc func nameDidChange() {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        addButton.isEnabled = !isSaving && (nameField.isHidden || !name.isEmpty)
        let title = workflow?.isRegistered == true ? L10n.Common.save : L10n.Common.add
        addButton.setTitle(title, for: .normal)
    }

    @objc func save() {
        guard addButton.isEnabled else { return }
        setSaving(true)
        let registration: Single<(faceId: Int?, person: APIFaceGroup?)>
        if let workflow {
            let target = nameField.isHidden ? selection : .new(nameField.text ?? "")
            registration = workflow.save(selection: target)
                .map { (workflow.faceId, $0) }
        } else {
            registration = apiWrapper.registerPersonFace(event: event.uuid).map { ($0, nil) }
        }
        registration
            .observe(on: MainScheduler.instance)
            .subscribe(
                with: self,
                onSuccess: { owner, result in
                    owner.publishRegistration(faceId: result.faceId, person: result.person)
                    owner.setSaving(false)
                    owner.close()
                },
                onFailure: { owner, error in owner.showSaveError(error) }
            )
            .disposed(by: disposeBag)
    }

    func setSaving(_ saving: Bool) {
        isSaving = saving
        if saving { view.endEditing(true) }
        scrollView.isUserInteractionEnabled = !saving
        updateLoader(isEnabled: saving, detailText: nil)
        nameDidChange()
    }

    func showSaveError(_ error: Error) {
        let isRegistered = workflow?.isRegistered == true
        if isRegistered { publishRegistration(faceId: workflow?.faceId, person: nil) }
        setSaving(false)
        let message = isRegistered ? L10n.Settings.Faces.Groups.assignmentError : error.localizedDescription
        let alert = UIAlertController(title: L10n.Common.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }

    func publishRegistration(faceId: Int?, person: APIFaceGroup?) {
        apiWrapper.forceUpdateFaces = true
        if let detail = event.detailX {
            var flags = (detail.flags ?? []).filter { flag in
                !["canLike", "canDislike", "canDisLike"].contains(flag)
            }
            flags.append("canDislike")
            let updatedDetail = detail.updatingFace(
                faceId: faceId.map(String.init) ?? detail.faceId,
                groupId: person?.groupId,
                groupName: person?.groupName,
                flags: flags
            )
            NotificationCenter.default.post(name: .updateEvent, object: event.withDetailX(updatedDetail))
        }
        NotificationCenter.default.post(name: .updateFaces, object: nil)
    }

    @objc func dismissIfOutsideCard(_ tap: UITapGestureRecognizer) {
        guard !card.bounds.contains(tap.location(in: card)) else { return }
        close()
    }

    @objc func close() {
        guard !isSaving else { return }
        dismiss(animated: true)
    }
}
