// Created by Александр Попов. Copyright © 2026 Sesameware.

import UIKit
import JGProgressHUD
import RxSwift
import RxCocoa
import RxDataSources

extension HistoryViewController {
    func makeEmptyStateView() -> UIView {
        let containerView = UIView(frame: tableView.bounds)
        containerView.backgroundColor = .clear
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.isHidden = true

        let titleLabel = UILabel.make(
            .bodySemibold,
            text: NSLocalizedString("history.emptyStateMessage", comment: "")
        )
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .SmartYard.gray
        titleLabel.textAlignment = .center

        containerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -32)
        ])

        return containerView
    }

    func updateEmptyState() {
        emptyStateView.isHidden = isHistoryLoading
            || hasLoadedAvailableDays == false
            || allAvailableDates.isEmpty == false
            || currentSectionModels.isEmpty == false
    }

    var selectedFlatIdsCount: Int {
        let selectedFlatIds = apptsFilter.value
        return selectedFlatIds.isEmpty ? viewModel.flatIds.count : selectedFlatIds.count
    }

    func configureFilterPanel() {
        toolbar.backgroundColor = .SmartYard.backgroundColor
        toolbar.layer.borderWidth = 0
        toolbar.layer.borderColor = UIColor.clear.cgColor
        toolbar.clipsToBounds = false

        configureFilterPanelChrome()
        configureEventsFilterButton()
        configureApartmentFilterButton()
        configureCalendarButton()

        updateFilterPanelColors()
    }

    private func configureFilterPanelChrome() {
        filterPanelView.backgroundColor = .clear
        filterPanelView.layer.cornerRadius = Constants.filterPanelCornerRadius
        filterPanelView.layer.borderWidth = 1
        filterPanelView.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)

        filterPanelEffectView.layer.cornerRadius = Constants.filterPanelCornerRadius
        filterPanelEffectView.clipsToBounds = true
        filterPanelEffectView.isUserInteractionEnabled = false

        filterPanelOverlayView.layer.cornerRadius = Constants.filterPanelCornerRadius
        filterPanelOverlayView.clipsToBounds = true
        filterPanelOverlayView.isUserInteractionEnabled = false
    }

    private func configureEventsFilterButton() {
        eventsFilterButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        eventsFilterButton.titleLabel?.lineBreakMode = .byTruncatingTail
        eventsFilterButton.titleLabel?.numberOfLines = 1
        eventsFilterButton.contentHorizontalAlignment = .leading
        eventsFilterButton.semanticContentAttribute = .forceRightToLeft
        eventsFilterButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        eventsFilterButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 0, right: -4)
        eventsFilterButton.setTitleColor(.SmartYard.blue, for: .normal)
        eventsFilterButton.setTitleColor(.SmartYard.blue.withAlphaComponent(0.75), for: .highlighted)
        eventsFilterButton.setImage(
            UIImage(named: "ArrowDown")?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        eventsFilterButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        eventsFilterButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        eventsFilterButton.addTarget(
            self,
            action: #selector(filterPanelButtonTouchDown(_:)),
            for: [.touchDown, .touchDragEnter]
        )
        eventsFilterButton.addTarget(
            self,
            action: #selector(filterPanelButtonTouchUp(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
        )
    }

    private func configureApartmentFilterButton() {
        appartmentFilterButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        appartmentFilterButton.titleLabel?.lineBreakMode = .byTruncatingTail
        appartmentFilterButton.titleLabel?.numberOfLines = 1
        appartmentFilterButton.contentHorizontalAlignment = .leading
        appartmentFilterButton.semanticContentAttribute = .forceRightToLeft
        appartmentFilterButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        appartmentFilterButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 0, right: -4)
        appartmentFilterButton.setTitleColor(.SmartYard.blue, for: .normal)
        appartmentFilterButton.setTitleColor(.SmartYard.blue.withAlphaComponent(0.75), for: .highlighted)
        appartmentFilterButton.setImage(
            UIImage(named: "ArrowDown")?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        appartmentFilterButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        appartmentFilterButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        appartmentFilterButton.addTarget(
            self,
            action: #selector(filterPanelButtonTouchDown(_:)),
            for: [.touchDown, .touchDragEnter]
        )
        appartmentFilterButton.addTarget(
            self,
            action: #selector(filterPanelButtonTouchUp(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
        )
    }

    private func configureCalendarButton() {
        calendarButton.layer.cornerRadius = Constants.calendarButtonSize / 2
        calendarButton.clipsToBounds = true
        calendarButton.tintColor = .SmartYard.blue
        calendarButton.setImage(
            UIImage(named: "calendar")?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        calendarButton.imageView?.contentMode = .scaleAspectFit
        calendarButton.setContentHuggingPriority(.required, for: .horizontal)
        calendarButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        calendarButton.addTarget(
            self,
            action: #selector(filterPanelButtonTouchDown(_:)),
            for: [.touchDown, .touchDragEnter]
        )
        calendarButton.addTarget(
            self,
            action: #selector(filterPanelButtonTouchUp(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
        )
    }

    func updateApartmentFilterTitle(_ title: String) {
        appartmentFilterButton.setTitle(title, for: .normal)
        appartmentFilterButton.accessibilityLabel = title
    }

    func updateFilterPanelLoadingState(_ isLoading: Bool) {
        filterPanelView.alpha = isLoading ? 0.6 : 1
        filterPanelView.isUserInteractionEnabled = isLoading == false
    }

    func updateFilterPanelColors() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        filterPanelOverlayView.backgroundColor = isDark
            ? UIColor.SmartYard.secondBackgroundColor.withAlphaComponent(0.92)
            : UIColor.SmartYard.secondBackgroundColor.withAlphaComponent(0.96)
        calendarButton.backgroundColor = isDark
            ? UIColor.SmartYard.backgroundColor.withAlphaComponent(0.45)
            : UIColor.SmartYard.backgroundColor.withAlphaComponent(0.65)
    }

    @objc private func filterPanelButtonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.14, delay: 0, options: [.allowUserInteraction]) {
            sender.alpha = 0.8
            sender.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }
    }

    @objc private func filterPanelButtonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.16, delay: 0, options: [.allowUserInteraction]) {
            sender.alpha = 1
            sender.transform = .identity
        }
    }
}
