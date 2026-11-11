// Created by Александр Попов. Copyright © 2026 Sesameware.

import UIKit
import RxCocoa
import RxRelay
import RxSwift
import SnapKit

extension NewAllowedCarViewController {
    func setupUI() {
        titleLabel.text = viewModel.originalCar == nil
            ? L10n.Settings.ShareCar.shareAccess : L10n.Settings.VehiclePass.editTitle
        titleLabel.numberOfLines = 0
        carNumberHintLabel.text = L10n.Settings.ShareCar.subtitle
        carNumberHintLabel.numberOfLines = 0
        textField.placeholder = L10n.Settings.ShareCar.platePlaceholder
        textField.accessibilityIdentifier = "vehicle-pass.number"
        textField.setKeyboardActionTitle(L10n.Settings.VehiclePass.continueButton)

        setupPeriodControls()
        setupDateFields()

        confirmButton.setTitle(viewModel.originalCar == nil ? L10n.Common.share : L10n.Common.save, for: .normal)
        retryFormatsButton.setTitle(L10n.Settings.VehiclePass.retryFormats, for: .normal)
        retryFormatsButton.titleLabel?.font = .SourceSansPro.regular(size: 14)
        retryFormatsButton.titleLabel?.numberOfLines = 0
        retryFormatsButton.isHidden = true
        retryFormatsButton.accessibilityIdentifier = "vehicle-pass.retry-formats"
        loadingIndicator.hidesWhenStopped = true
        confirmButton.titleLabel?.font = .SourceSansPro.semibold(size: 18)
        confirmButton.accessibilityIdentifier = "vehicle-pass.confirm"
        confirmButton.isEnabled = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = true
    }

    private func setupPeriodControls() {
        unlimitedTitle.text = L10n.Settings.VehiclePass.unlimited
        automaticEndTitle.text = L10n.Settings.VehiclePass.automaticEnd
        trackingTitle.text = L10n.Settings.VehiclePass.tracking
        [unlimitedTitle, automaticEndTitle, trackingTitle].forEach {
            $0.font = .SourceSansPro.regular(size: 18)
            $0.textColor = .SmartYard.semiBlack
            $0.numberOfLines = 0
        }
        startTitle.text = L10n.Settings.VehiclePass.start
        endTitle.text = L10n.Settings.VehiclePass.end
        [startTitle, endTitle, expirationLabel, trackingHint, periodError, numberError].forEach {
            $0.font = .SourceSansPro.regular(size: 14)
            $0.textColor = .SmartYard.gray
            $0.numberOfLines = 0
        }
        numberError.textColor = .SmartYard.incorrectDataRed
        numberError.text = L10n.Settings.VehiclePass.unsupportedNumber
        numberError.isHidden = true
        periodError.textColor = .SmartYard.incorrectDataRed
        periodError.text = L10n.Settings.VehiclePass.periodInvalid
        trackingHint.text = L10n.Settings.VehiclePass.trackingHint

        let validity = viewModel.originalCar?.validity
        unlimitedSwitch.setOn(validity?.isUnlimited ?? true, animated: false)
        automaticEndSwitch.setOn(validity?.lasts24Hours ?? true, animated: false)
        automaticWasEnabled = automaticEndSwitch.isOn
        hasStartBoundary = viewModel.originalCar == nil || validity?.validFrom != nil
        hasEndBoundary = viewModel.originalCar == nil || validity?.validTo != nil
        trackingSwitch.setOn(viewModel.originalCar?.watcherId != nil, animated: false)
        trackingGroup.isHidden = !viewModel.supportsTracking
        periodGroup.isHidden = !viewModel.supportsTimedAccess
        [unlimitedSwitch, automaticEndSwitch, trackingSwitch].forEach {
            $0.onTintColor = .SmartYard.darkGreen
            $0.clipsToBounds = false
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        unlimitedSwitch.accessibilityIdentifier = "vehicle-pass.unlimited"
        automaticEndSwitch.accessibilityIdentifier = "vehicle-pass.period24h"
        trackingSwitch.accessibilityIdentifier = "vehicle-pass.tracking"
    }

    private func setupDateFields() {
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = .current
        datePicker.calendar = calendar
        datePicker.timeZone = calendar.timeZone
        datePicker.sizeToFit()
        pickerToolbar.sizeToFit()
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(hideKeyboard))
        done.accessibilityIdentifier = "vehicle-pass.picker.done"
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        pickerToolbar.setItems([space, done], animated: false)

        for (index, field) in dateFields.enumerated() {
            field.font = .SourceSansPro.regular(size: 18)
            field.textColor = .SmartYard.blue
            field.backgroundColor = .SmartYard.backgroundColor
            field.layer.cornerRadius = 12
            field.tintColor = .clear
            field.inputView = datePicker
            field.inputAccessoryView = pickerToolbar
            field.delegate = self
            field.accessibilityIdentifier = [
                "vehicle-pass.start-date", "vehicle-pass.start-time",
                "vehicle-pass.end-date", "vehicle-pass.end-time"
            ][index]
        }
    }

    func setupConstraints() {
        card = titleLabel.superview
        let title = titleLabel!
        let hint = carNumberHintLabel!
        let number = textField!
        let icon = card.subviews.compactMap { $0 as? UIImageView }.first!
        [title, hint].forEach { label in
            label.removeConstraints(label.constraints.filter { $0.firstAttribute == .height })
        }
        card.removeConstraints(card.constraints)
        view.removeConstraints(view.constraints.filter {
            ($0.firstItem as? UIView) === card || ($0.secondItem as? UIView) === card
        })
        card.subviews.forEach { $0.removeFromSuperview() }
        card.removeFromSuperview()

        view.addSubview(availableArea) { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
        availableArea.addSubview(card) { make in
            make.centerX.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().inset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
            make.width.equalToSuperview().offset(-32).priority(750)
            make.width.lessThanOrEqualTo(view.readableContentGuide.snp.width)
            make.top.greaterThanOrEqualToSuperview().inset(12)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }
        card.pinSubview(outerStack)
        outerStack.add {
            titleGroup
            numberGroup
            scrollView
            retryFormatsButton
            loadingIndicator
            confirmButton
        }
        scrollView.addSubview(content) { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
        }
        content.snp.makeConstraints { $0.width.equalTo(scrollView.frameLayoutGuide.snp.width) }
        scrollView.snp.makeConstraints { $0.height.equalTo(content.snp.height).priority(249) }
        confirmButton.snp.makeConstraints { $0.height.equalTo(52) }

        titleGroup.add { title; hint }
        setupNumberLayout(number: number, icon: icon)
        setupPeriodLayout()

        let hide = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        hide.cancelsTouchesInView = false
        hide.delegate = self
        card.addGestureRecognizer(hide)
    }

    private func setupNumberLayout(number: UIView, icon: UIView) {
        icon.setContentHuggingPriority(.required, for: .horizontal)
        let numberRow = UIStackView.horizontal(spacing: 20, alignment: .center)
        numberRow.add { number; icon }
        let numberLine = UIView()
        numberLine.backgroundColor = .SmartYard.grayBorder
        numberLine.snp.makeConstraints { $0.height.equalTo(1) }
        numberGroup.add { numberRow; numberLine; numberError }
    }

    private func setupPeriodLayout() {
        trackingGroup.add {
            optionRow(label: trackingTitle, control: trackingSwitch)
            trackingHint
        }
        manualEndContent.add {
            endTitle
            dateRow(date: endDateField, time: endTimeField)
        }
        let startContent = UIStackView.vertical(spacing: 8)
        startContent.add {
            startTitle
            dateRow(date: startDateField, time: startTimeField)
        }
        endContent.clipsToBounds = true
        endContent.addSubview(expirationLabel) { make in
            make.top.leading.trailing.equalToSuperview()
        }
        endContent.addSubview(manualEndContent) { make in
            make.top.leading.trailing.equalToSuperview()
        }
        endContent.snp.makeConstraints { make in
            automaticEndHeight = make.height.equalTo(expirationLabel.snp.height).constraint
            manualEndHeight = make.height.equalTo(manualEndContent.snp.height).constraint
        }
        manualEndHeight.deactivate()
        limitedContent.add {
            startContent
            optionRow(label: automaticEndTitle, control: automaticEndSwitch)
            endContent
            periodError
        }
        periodGroup.add {
            optionRow(label: unlimitedTitle, control: unlimitedSwitch)
            limitedContent
        }
        content.add { trackingGroup; periodGroup }
    }

    private func optionRow(label: UILabel, control: UISwitch) -> UIStackView {
        // Use UIKit's fitting size and reserve room for the native control's visual edge.
        control.sizeToFit()
        let nativeSize = control.sizeThatFits(.zero)
        control.snp.makeConstraints { $0.size.equalTo(nativeSize) }
        let controlContainer = control.insets(UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 16))
        let row = UIStackView.horizontal(spacing: 12, alignment: .center)
        row.add { label; controlContainer }
        return row
    }

    private func dateRow(date: UITextField, time: UITextField) -> UIStackView {
        let row = UIStackView.horizontal(spacing: 12, alignment: .center)
        row.add { date; time }
        date.snp.makeConstraints { make in
            make.height.equalTo(56)
            make.width.equalTo(time.snp.width).multipliedBy(2)
        }
        time.snp.makeConstraints { $0.height.equalTo(56) }
        return row
    }

}
