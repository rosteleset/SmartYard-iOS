//
//  TrackedEventsViewController.swift
//  SmartYard
//
//  Created by Александр Попов on 29.05.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import RxCocoa
import RxDataSources
import RxSwift
import UIKit

final class TrackedEventsViewController: BaseViewController {
    private let viewModel: TrackedEventsViewModel
    private let contentView = TrackedEventsView()
    private lazy var dataSource = makeDataSource()
    private let commentsTextFieldDelegate = MaxLengthTextFieldDelegate(maxLength: 30)
    private let deleteTrigger = PublishSubject<APITrackedEvent>()
    private let editTrigger = PublishSubject<(APITrackedEvent, String)>()

    init(viewModel: TrackedEventsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)

        bind()
    }

    private func bind() {
        let input = TrackedEventsViewModel.Input(
            viewWillAppearTrigger: rx.viewWillAppear.asDriverOnErrorJustComplete().mapToVoid(),
            backTrigger: contentView.fakeNavBar.rx.backButtonTap.asDriver(),
            addTrigger: contentView.addButton.rx.tap.asDriver(),
            deleteTrigger: deleteTrigger.asDriverOnErrorJustComplete(),
            editTrigger: editTrigger.asDriverOnErrorJustComplete()
        )

        let output = viewModel.transform(input)

        output.address
            .drive(contentView.addressLabel.rx.text)
            .disposed(by: disposeBag)

        output.events
            .do(onNext: { [weak self] events in
                self?.contentView.setEmptyStateVisible(events.isEmpty)
            })
            .map { events in
                [TrackedEventsSectionModel(identity: "trackedEvents", items: events)]
            }
            .drive(contentView.tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        output.isLoading
            .drive(
                onNext: { [weak self] isLoading in
                    self?.contentView.setLoading(isLoading)
                }
            )
            .disposed(by: disposeBag)
    }

    private func confirmDelete(event: APITrackedEvent) {
        let cancelAction = UIAlertAction(title: L10n.Common.cancel, style: .cancel)
        let deleteAction = UIAlertAction(title: L10n.Common.delete, style: .destructive) { [weak self] _ in
            self?.deleteTrigger.onNext(event)
        }

        let alert = UIAlertController(
            title: L10n.Settings.TrackedEvents.DeleteConfirmation.title,
            message: nil,
            preferredStyle: .alert
        )
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        present(alert, animated: true)
    }

    private func showEditCommentDialog(for event: APITrackedEvent) {
        let alert = UIAlertController(
            title: L10n.History.EventTracking.Comment.title,
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { [commentsTextFieldDelegate] textField in
            textField.text = event.normalizedComments
            textField.placeholder = String.localizedStringWithFormat(
                L10n.History.EventTracking.Comment.placeholderFormat,
                commentsTextFieldDelegate.maxLength
            )
            textField.delegate = commentsTextFieldDelegate
            textField.clearButtonMode = .whileEditing
        }

        let cancelAction = UIAlertAction(title: L10n.Common.cancel, style: .cancel)
        let okAction = UIAlertAction(title: L10n.Common.ok, style: .default) { [weak self, weak alert] _ in
            let text = alert?.textFields?.first?.text ?? ""
            guard text != event.normalizedComments else { return }

            self?.editTrigger.onNext((event, String(text.prefix(30))))
        }

        alert.addAction(cancelAction)
        alert.addAction(okAction)

        present(alert, animated: true)
    }

    private func makeDataSource() -> RxTableViewSectionedAnimatedDataSource<TrackedEventsSectionModel> {
        let dataSource = RxTableViewSectionedAnimatedDataSource<TrackedEventsSectionModel>(
            configureCell: { _, tableView, indexPath, event in
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: TrackedEventCell.reuseIdentifier,
                    for: indexPath
                ) as? TrackedEventCell
                guard let cell else { return UITableViewCell() }

                cell.configure(with: event)
                return cell
            }
        )

        dataSource.canEditRowAtIndexPath = { _, _ in true }
        dataSource.animationConfiguration = AnimationConfiguration(
            insertAnimation: .fade,
            reloadAnimation: .fade,
            deleteAnimation: .fade
        )

        return dataSource
    }
}

extension TrackedEventsViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: L10n.Common.delete) { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }
            guard let event = self.dataSource.sectionModels[safe: indexPath.section]?.items[safe: indexPath.row] else {
                completion(false)
                return
            }

            self.confirmDelete(event: event)
            completion(true)
        }

        let editAction = UIContextualAction(style: .normal, title: L10n.Common.edit) { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }
            guard let event = self.dataSource.sectionModels[safe: indexPath.section]?.items[safe: indexPath.row] else {
                completion(false)
                return
            }

            self.showEditCommentDialog(for: event)
            completion(true)
        }
        editAction.backgroundColor = .SmartYard.blue

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        configuration.performsFirstActionWithFullSwipe = false

        return configuration
    }
}

private final class MaxLengthTextFieldDelegate: NSObject, UITextFieldDelegate {
    let maxLength: Int

    init(maxLength: Int) {
        self.maxLength = maxLength
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let currentText = textField.text,
              let range = Range(range, in: currentText) else {
            return true
        }

        let updated = currentText.replacingCharacters(in: range, with: string)
        return updated.count <= maxLength
    }
}

struct TrackedEventsSectionModel: AnimatableSectionModelType {
    let identity: String
    var items: [APITrackedEvent]
}

extension TrackedEventsSectionModel: SectionModelType {
    init(original: TrackedEventsSectionModel, items: [APITrackedEvent]) {
        self = original
        self.items = items
    }
}

extension APITrackedEvent: IdentifiableType {
    var identity: Int { watcherId }
}
