// Created by Александр Попов. Copyright © 2026 Sesameware.

import UIKit
import RxCocoa
import RxRelay
import RxSwift
import SnapKit

final class NewAllowedCarViewController: BaseViewController {
    @IBOutlet private weak var textField: SmartYardLicensePlateTextField!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var carNumberHintLabel: UILabel!

    private enum PickerTarget { case startDate, startTime, endDate, endTime }

    private let dismissTap = UITapGestureRecognizer()
    private let availableArea = UIView()
    private let scrollView = UIScrollView()
    private let content = UIStackView.vertical(spacing: 20)
    private let outerStack = UIStackView.vertical(
        paddings: .init(top: 28, leading: 24, bottom: 24, trailing: 24), spacing: 20
    )
    private let titleGroup = UIStackView.vertical(spacing: 12)
    private let numberGroup = UIStackView.vertical(spacing: 8)
    private let trackingGroup = UIStackView.vertical(spacing: 4)
    private let periodGroup = UIStackView.vertical(spacing: 12)
    private let limitedContent = UIStackView.vertical(spacing: 12)
    private let manualEndContent = UIStackView.vertical(spacing: 8)
    private let unlimitedSwitch = UISwitch()
    private let automaticEndSwitch = UISwitch()
    private let trackingSwitch = UISwitch()
    private let unlimitedTitle = UILabel()
    private let automaticEndTitle = UILabel()
    private let trackingTitle = UILabel()
    private let startTitle = UILabel()
    private let endTitle = UILabel()
    private let expirationLabel = UILabel()
    private let trackingHint = UILabel()
    private let periodError = UILabel()
    private let numberError = UILabel()
    private let startDateField = SmartYardBorderedTextField()
    private let startTimeField = SmartYardBorderedTextField()
    private let endDateField = SmartYardBorderedTextField()
    private let endTimeField = SmartYardBorderedTextField()
    private let datePicker = UIDatePicker()
    private let pickerToolbar = UIToolbar()
    private let confirmButton = BlueButton(frame: .zero)
    private let draftCar = BehaviorRelay<AllowedCar?>(value: nil)
    private let retryFormatsButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private var card: UIView!
    private var selectedPicker: PickerTarget?
    private var automaticWasEnabled = true
    private var startDate: Date
    private var manualEndDate: Date
    private var hasStartBoundary = true
    private var hasEndBoundary = true
    private let calendar: Calendar
    private let viewModel: NewAllowedCarViewModel

    init(viewModel: NewAllowedCarViewModel) {
        self.viewModel = viewModel
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = viewModel.timeZone
        self.calendar = calendar
        let now = calendar.dateInterval(of: .minute, for: Date())?.start ?? Date()
        self.startDate = viewModel.originalCar?.validFrom ?? now
        self.manualEndDate = viewModel.originalCar?.validTo ?? now.addingTimeInterval(24 * 60 * 60)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var dateFields: [SmartYardBorderedTextField] {
        [startDateField, startTimeField, endDateField, endTimeField]
    }
    private var effectiveEnd: Date {
        automaticEndSwitch.isOn ? startDate.addingTimeInterval(24 * 60 * 60) : manualEndDate
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bind()
        if let car = viewModel.originalCar {
            if car.countryCode == "ru" {
                textField.configure(number: car.rawNumber)
            } else {
                textField.text = car.displayedNumber
                // Sesame's current keyboard supports RU entry. Keep foreign identifiers
                // intact while allowing their period and tracking settings to be edited.
                textField.isEnabled = false
            }
        }
        updatePeriod()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewModel.originalCar == nil { textField.becomeFirstResponder() }
    }

}

extension NewAllowedCarViewController {
    private func setupUI() {
        titleLabel.text = viewModel.originalCar == nil
            ? L10n.Settings.ShareCar.shareAccess : L10n.Settings.VehiclePass.editTitle
        titleLabel.numberOfLines = 0
        carNumberHintLabel.text = L10n.Settings.ShareCar.subtitle
        carNumberHintLabel.numberOfLines = 0
        textField.placeholder = L10n.Settings.ShareCar.platePlaceholder
        textField.accessibilityIdentifier = "vehicle-pass.number"

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
        unlimitedSwitch.setOn(validity?.isUnlimited ?? false, animated: false)
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

        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = .current
        datePicker.calendar = calendar
        datePicker.timeZone = calendar.timeZone
        datePicker.sizeToFit()
        pickerToolbar.sizeToFit()
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(hideKeyboard))
        done.accessibilityIdentifier = "vehicle-pass.picker.done"
        pickerToolbar.setItems([
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), done
        ], animated: false)

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
        scrollView.showsVerticalScrollIndicator = false
    }

    private func setupConstraints() {
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
        icon.setContentHuggingPriority(.required, for: .horizontal)
        let numberRow = UIStackView.horizontal(spacing: 20, alignment: .center)
        numberRow.add { number; icon }
        let numberLine = UIView()
        numberLine.backgroundColor = .SmartYard.grayBorder
        numberLine.snp.makeConstraints { $0.height.equalTo(1) }
        numberGroup.add { numberRow; numberLine; numberError }

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
        limitedContent.add {
            startContent
            optionRow(label: automaticEndTitle, control: automaticEndSwitch)
            expirationLabel
            manualEndContent
            periodError
        }
        periodGroup.add {
            optionRow(label: unlimitedTitle, control: unlimitedSwitch)
            limitedContent
        }
        content.add { trackingGroup; periodGroup }

        let hide = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        hide.cancelsTouchesInView = false
        hide.delegate = self
        card.addGestureRecognizer(hide)
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

    private func bind() {
        textField.rx.controlEvent(.editingChanged)
            .subscribe(with: self) { owner, _ in owner.updateDraft() }
            .disposed(by: disposeBag)
        unlimitedSwitch.rx.isOn.asDriver().drive(with: self) { owner, unlimited in
            if !unlimited && !owner.hasStartBoundary && !owner.hasEndBoundary {
                owner.hasStartBoundary = true
                owner.hasEndBoundary = true
            }
            owner.updatePeriod()
        }.disposed(by: disposeBag)
        automaticEndSwitch.rx.isOn.asDriver().drive(with: self) { owner, automatic in
            if automatic {
                owner.hasStartBoundary = true
                owner.hasEndBoundary = true
            } else if owner.automaticWasEnabled {
                owner.manualEndDate = owner.startDate.addingTimeInterval(24 * 60 * 60)
            }
            owner.automaticWasEnabled = automatic
            owner.updatePeriod()
        }.disposed(by: disposeBag)
        datePicker.rx.date.skip(1).subscribe(with: self) { owner, date in
            owner.applyPickerDate(date)
        }.disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(UIResponder.keyboardDidChangeFrameNotification)
            .subscribe(with: self) { owner, _ in owner.revealSelectedField() }
            .disposed(by: disposeBag)

        dismissTap.delegate = self
        view.addGestureRecognizer(dismissTap)
        let confirm = Driver.merge(confirmButton.rx.tap.asDriver(), textField.shareButtonTapped)
        let output = viewModel.transform(.init(
            closeTrigger: dismissTap.rx.event.mapToVoid().asDriver(onErrorJustReturn: ()),
            car: draftCar.asDriver(), trackingEnabled: trackingSwitch.rx.isOn.asDriver(),
            addAccessTrigger: confirm, retryFormatsTrigger: retryFormatsButton.rx.tap.asDriver()
        ))
        output.canConfirm.drive(with: self) { owner, allowed in
            owner.confirmButton.isEnabled = allowed
            owner.textField.setFormConfirmationAllowed(allowed)
        }.disposed(by: disposeBag)
        output.isLoading.drive(with: self) { owner, loading in
            if loading { owner.hideKeyboard() }
            loading ? owner.loadingIndicator.startAnimating() : owner.loadingIndicator.stopAnimating()
            owner.scrollView.isUserInteractionEnabled = !loading
            owner.textField.isUserInteractionEnabled = !loading
            owner.retryFormatsButton.isEnabled = !loading
        }.disposed(by: disposeBag)
        output.unsupportedNumber.drive(with: self) { owner, unsupported in
            owner.numberError.isHidden = !unsupported
        }.disposed(by: disposeBag)
        output.formatsUnavailable.drive(with: self) { owner, unavailable in
            owner.retryFormatsButton.isHidden = !unavailable
        }.disposed(by: disposeBag)
    }

    private var validity: LicensePlateValidity {
        guard viewModel.supportsTimedAccess, !unlimitedSwitch.isOn else { return .unlimited }
        return LicensePlateValidity(
            validFrom: hasStartBoundary ? startDate : nil,
            validTo: automaticEndSwitch.isOn || hasEndBoundary ? effectiveEnd : nil
        )
    }

    private func updateDraft() {
        let original = viewModel.originalCar
        let foreignCar = original.flatMap { $0.countryCode != "ru" ? $0 : nil }
        let fixedForeignNumber = foreignCar != nil
        guard fixedForeignNumber || textField.hasCompleteNumber else {
            draftCar.accept(nil)
            return
        }
        let period = validity
        draftCar.accept(AllowedCar(
            rawNumber: foreignCar?.rawNumber ?? LicencePlateFormatter.unformat(text: textField.text ?? ""),
            countryCode: foreignCar?.countryCode ?? textField.countryCode,
            validFrom: period.validFrom, validTo: period.validTo, watcherId: original?.watcherId
        ))
    }

    private func updatePeriod() {
        limitedContent.isHidden = unlimitedSwitch.isOn
        manualEndContent.isHidden = automaticEndSwitch.isOn
        expirationLabel.isHidden = !automaticEndSwitch.isOn
        startDateField.text = hasStartBoundary
            ? formatted(startDate, pattern: "d MMM yyyy") : L10n.Settings.VehiclePass.noBoundary
        startTimeField.text = hasStartBoundary ? formatted(startDate, pattern: "HH:mm") : "—"
        let hasEnd = automaticEndSwitch.isOn || hasEndBoundary
        endDateField.text = hasEnd
            ? formatted(effectiveEnd, pattern: "d MMM yyyy") : L10n.Settings.VehiclePass.noBoundary
        endTimeField.text = hasEnd ? formatted(effectiveEnd, pattern: "HH:mm") : "—"
        expirationLabel.text = String(
            format: L10n.Settings.VehiclePass.expirationFormat, formatted(effectiveEnd, pattern: "d MMMM, HH:mm")
        )
        periodError.isHidden = validity.isValid
        updateDraft()
    }

    private func formatted(_ date: Date, pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }

    private func applyPickerDate(_ date: Date) {
        guard let target = selectedPicker else { return }
        let isStart = target == .startDate || target == .startTime
        let isDate = target == .startDate || target == .endDate
        let base = isStart ? startDate : manualEndDate
        let day = calendar.dateComponents([.year, .month, .day], from: isDate ? date : base)
        let time = calendar.dateComponents([.hour, .minute], from: isDate ? base : date)
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = time.hour
        components.minute = time.minute
        guard let merged = calendar.date(from: components) else { return }
        if isStart {
            startDate = merged
            hasStartBoundary = true
        } else {
            manualEndDate = merged
            hasEndBoundary = true
        }
        updatePeriod()
    }

    private func revealSelectedField() {
        guard let field = dateFields.first(where: { $0.isFirstResponder }) else {
            if !textField.isFirstResponder { scrollView.setContentOffset(.zero, animated: false) }
            return
        }
        view.layoutIfNeeded()
        scrollView.scrollRectToVisible(field.convert(field.bounds, to: scrollView).insetBy(dx: 0, dy: -8), animated: true)
    }

    @objc private func hideKeyboard() { view.endEditing(true) }
}

extension NewAllowedCarViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer === dismissTap {
            return !(touch.view?.isDescendant(of: card) ?? false)
        }
        var candidate = touch.view
        while let view = candidate {
            if view is UIControl { return false }
            candidate = view.superview
        }
        return true
    }
}

extension NewAllowedCarViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ field: UITextField) -> Bool {
        guard let index = dateFields.firstIndex(where: { $0 === field }) else { return true }
        selectedPicker = [PickerTarget.startDate, .startTime, .endDate, .endTime][index]
        datePicker.datePickerMode = index == 0 || index == 2 ? .date : .time
        datePicker.setDate(index < 2 ? startDate : manualEndDate, animated: false)
        return true
    }

    func textField(_ field: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        false
    }
}
