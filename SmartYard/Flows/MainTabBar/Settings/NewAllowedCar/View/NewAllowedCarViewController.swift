// Created by Александр Попов. Copyright © 2026 Sesameware.

import UIKit
import RxCocoa
import RxRelay
import RxSwift
import SnapKit

final class NewAllowedCarViewController: BaseViewController {
    @IBOutlet private(set) weak var textField: SmartYardLicensePlateTextField!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var carNumberHintLabel: UILabel!

    private enum PickerTarget { case startDate, startTime, endDate, endTime }

    private let dismissTap = UITapGestureRecognizer()
    let availableArea = UIView()
    let scrollView = UIScrollView()
    let content = UIStackView.vertical(spacing: 20)
    let outerStack = UIStackView.vertical(
        paddings: .init(top: 28, leading: 24, bottom: 24, trailing: 24), spacing: 20
    )
    let titleGroup = UIStackView.vertical(spacing: 12)
    let numberGroup = UIStackView.vertical(spacing: 8)
    let trackingGroup = UIStackView.vertical(spacing: 4)
    let periodGroup = UIStackView.vertical(spacing: 12)
    let limitedContent = UIStackView.vertical(spacing: 12)
    let manualEndContent = UIStackView.vertical(spacing: 8)
    let endContent = UIView()
    var automaticEndHeight: Constraint!
    var manualEndHeight: Constraint!
    let unlimitedSwitch = UISwitch()
    let automaticEndSwitch = UISwitch()
    let trackingSwitch = UISwitch()
    let unlimitedTitle = UILabel()
    let automaticEndTitle = UILabel()
    let trackingTitle = UILabel()
    let startTitle = UILabel()
    let endTitle = UILabel()
    let expirationLabel = UILabel()
    let trackingHint = UILabel()
    let periodError = UILabel()
    let numberError = UILabel()
    let startDateField = SmartYardBorderedTextField()
    let startTimeField = SmartYardBorderedTextField()
    let endDateField = SmartYardBorderedTextField()
    let endTimeField = SmartYardBorderedTextField()
    let datePicker = UIDatePicker()
    let pickerToolbar = UIToolbar()
    let confirmButton = BlueButton(frame: .zero)
    private let draftCar = BehaviorRelay<AllowedCar?>(value: nil)
    private let showsSettings = BehaviorRelay(value: false)
    private let continueTrigger = PublishRelay<Void>()
    private let saveTrigger = PublishRelay<Void>()
    private var isAdvancingToSettings = false
    let retryFormatsButton = UIButton(type: .system)
    let loadingIndicator = UIActivityIndicatorView(style: .medium)
    var card: UIView!
    private var selectedPicker: PickerTarget?
    var automaticWasEnabled = true
    private var startDate: Date
    private var manualEndDate: Date
    var hasStartBoundary = true
    var hasEndBoundary = true
    var calendar: Calendar
    let viewModel: NewAllowedCarViewModel

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

    var dateFields: [SmartYardBorderedTextField] {
        [startDateField, startTimeField, endDateField, endTimeField]
    }
    private var effectiveEnd: Date {
        automaticEndSwitch.isOn ? startDate.addingTimeInterval(24 * 60 * 60) : manualEndDate
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        showsSettings.accept(viewModel.originalCar != nil)
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
    private func bind() {
        bindEditorControls()

        dismissTap.delegate = self
        view.addGestureRecognizer(dismissTap)
        let input = NewAllowedCarViewModel.Input(
            closeTrigger: dismissTap.rx.event.mapToVoid().asDriver(onErrorJustReturn: ()),
            car: draftCar.asDriver(),
            trackingEnabled: trackingSwitch.rx.isOn.asDriver(),
            addAccessTrigger: saveTrigger.asDriverOnErrorJustComplete(),
            retryFormatsTrigger: retryFormatsButton.rx.tap.asDriver()
        )
        let output = viewModel.transform(input)
        bindFormActions(output)
        bindFormFeedback(output)
    }

    private func bindEditorControls() {
        textField.rx.controlEvent(.editingDidBegin)
            .subscribe(with: self) { owner, _ in owner.setSettingsVisible(false) }
            .disposed(by: disposeBag)
        textField.rx.controlEvent(.editingChanged)
            .subscribe(with: self) { owner, _ in owner.updateDraft() }
            .disposed(by: disposeBag)
        unlimitedSwitch.rx.isOn.asDriver()
            .drive(with: self) { owner, unlimited in
                if !unlimited && !owner.hasStartBoundary && !owner.hasEndBoundary {
                    owner.hasStartBoundary = true
                    owner.hasEndBoundary = true
                }
                owner.updatePeriod(animated: true)
            }
            .disposed(by: disposeBag)
        automaticEndSwitch.rx.isOn.asDriver()
            .drive(with: self) { owner, automatic in
                if automatic {
                    owner.hasStartBoundary = true
                    owner.hasEndBoundary = true
                } else if owner.automaticWasEnabled {
                    owner.manualEndDate = owner.startDate.addingTimeInterval(24 * 60 * 60)
                }
                owner.automaticWasEnabled = automatic
                owner.updatePeriod(animated: true)
            }
            .disposed(by: disposeBag)
        datePicker.rx.date
            .skip(1)
            .subscribe(with: self) { owner, date in
                owner.applyPickerDate(date)
            }
            .disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(UIResponder.keyboardDidChangeFrameNotification)
            .subscribe(with: self) { owner, _ in owner.revealSelectedField() }
            .disposed(by: disposeBag)
    }

    private func bindFormActions(_ output: NewAllowedCarViewModel.Output) {
        Driver.combineLatest(showsSettings.asDriver(), output.canContinue, output.canConfirm)
            .drive(with: self) { owner, values in
                let (visible, canContinue, canConfirm) = values
                owner.confirmButton.isEnabled = visible ? canConfirm : canContinue
                owner.textField.setFormConfirmationAllowed(canContinue)
            }
            .disposed(by: disposeBag)
        Driver.combineLatest(output.supportsTimedAccess, output.supportsTracking)
            .drive(with: self) { owner, values in
                let (timed, tracking) = values
                owner.periodGroup.isHidden = !timed
                owner.trackingGroup.isHidden = !tracking
                owner.applySettingsVisibility()
                owner.updatePeriod()
            }
            .disposed(by: disposeBag)
        confirmButton.rx.tap
            .subscribe(with: self) { owner, _ in
                let action = owner.showsSettings.value ? owner.saveTrigger : owner.continueTrigger
                action.accept(())
            }
            .disposed(by: disposeBag)
        Driver.merge(continueTrigger.asDriverOnErrorJustComplete(), textField.shareButtonTapped)
            .withLatestFrom(output.canContinue)
            .filter { $0 }
            .drive(with: self) { owner, _ in owner.continueToSettings() }
            .disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(UIResponder.keyboardDidHideNotification)
            .subscribe(with: self) { owner, _ in
                if owner.isAdvancingToSettings { owner.showSettings() }
            }
            .disposed(by: disposeBag)
    }

    private func bindFormFeedback(_ output: NewAllowedCarViewModel.Output) {
        output.isLoading
            .drive(with: self) { owner, loading in
                if loading {
                    owner.hideKeyboard()
                    owner.loadingIndicator.startAnimating()
                } else {
                    owner.loadingIndicator.stopAnimating()
                }
                owner.scrollView.isUserInteractionEnabled = !loading
                owner.textField.isUserInteractionEnabled = !loading
                owner.retryFormatsButton.isEnabled = !loading
            }
            .disposed(by: disposeBag)
        output.unsupportedNumber
            .drive(with: self) { owner, unsupported in
                owner.numberError.isHidden = !unsupported
            }
            .disposed(by: disposeBag)
        output.formatsUnavailable
            .drive(with: self) { owner, unavailable in
                owner.retryFormatsButton.isHidden = !unavailable
            }
            .disposed(by: disposeBag)
    }

    private func continueToSettings() {
        guard !isAdvancingToSettings else { return }
        if textField.isFirstResponder {
            isAdvancingToSettings = true
            textField.resignFirstResponder()
        } else {
            showSettings()
        }
    }

    private func showSettings() {
        isAdvancingToSettings = false
        calendar.timeZone = viewModel.timeZone
        datePicker.calendar = calendar
        datePicker.timeZone = calendar.timeZone
        scrollView.setContentOffset(.zero, animated: false)
        setSettingsVisible(true)
    }

    private func setSettingsVisible(_ visible: Bool) {
        guard showsSettings.value != visible else { return }
        view.layoutIfNeeded()
        if visible { scrollView.alpha = 0 }
        UIView.animate(
            withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.28,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState]
        ) {
            self.showsSettings.accept(visible)
            self.applySettingsVisibility()
            self.scrollView.alpha = visible ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }

    private func applySettingsVisibility() {
        let visible = showsSettings.value
        scrollView.isHidden = !visible || (!viewModel.supportsTimedAccess && !viewModel.supportsTracking)
        let title = visible
            ? (viewModel.originalCar == nil ? L10n.Common.share : L10n.Common.save)
            : L10n.Settings.VehiclePass.continueButton
        confirmButton.setTitle(title, for: .normal)
    }

    var validity: LicensePlateValidity {
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
            validFrom: period.validFrom,
            validTo: period.validTo,
            watcherId: original?.watcherId
        ))
    }

    private func updatePeriod(animated: Bool = false) {
        let hidesAllDates = unlimitedSwitch.isOn && dateFields.contains { $0.isFirstResponder }
        let hidesEndDate = automaticEndSwitch.isOn && [endDateField, endTimeField].contains { $0.isFirstResponder }
        if hidesAllDates || hidesEndDate { hideKeyboard() }
        let updateVisibility = {
            self.limitedContent.isHidden = self.unlimitedSwitch.isOn
            self.limitedContent.alpha = self.unlimitedSwitch.isOn ? 0 : 1
            let automatic = self.automaticEndSwitch.isOn
            if automatic {
                self.manualEndHeight.deactivate()
                self.automaticEndHeight.activate()
            } else {
                self.automaticEndHeight.deactivate()
                self.manualEndHeight.activate()
            }
            self.manualEndContent.alpha = automatic ? 0 : 1
            self.manualEndContent.isUserInteractionEnabled = !automatic
            self.manualEndContent.accessibilityElementsHidden = automatic
            self.expirationLabel.alpha = automatic ? 1 : 0
            self.expirationLabel.accessibilityElementsHidden = !automatic
        }
        view.layoutIfNeeded()
        if animated, view.window != nil {
            UIView.animate(
                withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.28,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState]
            ) {
                updateVisibility()
                self.view.layoutIfNeeded()
            }
        } else {
            updateVisibility()
        }
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

    @objc func hideKeyboard() { view.endEditing(true) }
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
