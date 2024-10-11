//
//  ContractViewCell.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 31.05.2024.
//  Copyright © 2024 Layka. All rights reserved.
//
// swiftlint:disable function_body_length type_body_length

import UIKit
import RxSwift
import RxCocoa

class ContractViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var faceView: UIView!
    @IBOutlet private weak var contractNameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var paymentButton: UIButton!
    @IBOutlet private weak var settingsButton: UIButton!
    @IBOutlet private weak var detailButton: UIButton!
    @IBOutlet private weak var parentControlView: UIView!
    @IBOutlet private weak var parentControlButton: UIButton!
    @IBOutlet private weak var parentControlSwitch: UISwitch!
    @IBOutlet private weak var limitEnabledLabel: UILabel!
    @IBOutlet private weak var limitButton: UIButton!
    
    @IBOutlet private weak var tooltipView: UIView!
    @IBOutlet private weak var tooltipLabel: UILabel!
    @IBOutlet private weak var servicesStackView: UIStackView!
    @IBOutlet private weak var cctvButton: UIButton!
    @IBOutlet private weak var domophoneButton: UIButton!
    @IBOutlet private weak var internetButton: UIButton!
    @IBOutlet private weak var monitorButton: UIButton!
    @IBOutlet private weak var kabelTVButton: UIButton!
    @IBOutlet private weak var barrierButton: UIButton!

    @IBOutlet private weak var detailView: UIView!
    @IBOutlet private weak var detailCloseButton: UIButton!
    @IBOutlet private weak var detailSendButton: UIButton!
    @IBOutlet private weak var detailRangeLabel: UILabel!
    @IBOutlet private weak var detailTableView: UITableView!
    
    @IBOutlet private weak var paymentButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tooltipCenterXConstraint: NSLayoutConstraint!
    
    weak var delegate: ContractCellProtocol?
    var contract: ContractFaceObject?
    var tooltipCount: Int = 0
    var servicesExits: [SettingsServiceType] = []
    var visibleTooltipService: SettingsServiceType?
    private var timer: Timer?

    private let rotateOut = CATransform3D(rotationAngle: .pi / 2, x: 0, y: 1, z: 0)
    private let rotateIn = CATransform3D(rotationAngle: 0, x: 0, y: 1, z: 0)

    @IBAction private func contractSettings() {
        delegate?.didTapSettings(for: self)
    }
    
    @IBAction private func parentControlInfoTap() {
        delegate?.didTapParentControlInfo(for: self)
    }
    
    @IBAction private func parentControlTap() {
        delegate?.didTapParentControl(for: self)
    }
    
    @IBAction private func showDetailTap() {
        showDetailPan()
    }
    
    @IBAction private func hideDetailTap() {
        hideDetailPan()
    }
    
    @IBAction private func changeDetailsRange() {
        delegate?.didTapChangeRangeDetails(for: self)
    }
    
    @IBAction private func sendDetails() {
        delegate?.didTapSendHistoryDetails(for: self)
    }
    
    @IBAction private func paymentTap() {
        delegate?.didTapPayContract(for: self)
    }
    
    @IBAction private func activateLimitTap() {
        delegate?.didTapLimit(for: self)
    }
    
    @IBAction private func showTooltip(sender: UIButton) {
        let keyButton: SettingsServiceType? = {
            switch sender {
            case cctvButton:
                return .cctv
            case domophoneButton:
                return .domophone
            case internetButton:
                return .internet
            case monitorButton:
                return .iptv
            case kabelTVButton:
                return .ctv
            case barrierButton:
                return .barrier
            default:
                return nil
            }
        }()
        guard let buttontype = keyButton else {
            return
        }
        timer?.invalidate()
        if visibleTooltipService == buttontype {
            visibleTooltipService = nil
            UIView.animate(
                withDuration: 0.5,
                animations: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.tooltipView.alpha = 0
                },
                completion: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    self.tooltipView.isHidden = true
                }
            )
            return
        }
        tooltipLabel.text = buttontype.tooltipTitle
        var index: CGFloat?
        
        servicesExits.enumerated().forEach { offset, element in
            if element == buttontype {
                index = CGFloat(offset)
            }
        }
        guard let uindex = index else {
            return
        }
        
        tooltipView.isHidden = false
        visibleTooltipService = buttontype
        
        UIView.animate(
            withDuration: 0.5,
            animations: { [weak self] in
                guard let self = self else {
                    return
                }
                self.tooltipView.alpha = 1
                self.tooltipCenterXConstraint.constant = (uindex - CGFloat(self.tooltipCount - 1) / 2) * (40 + self.servicesStackView.spacing)
            },
            completion: { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: self.onTimer)
            }
        )
    }
    
    func onTimer(_: Timer) {
        visibleTooltipService = nil
        UIView.animate(
            withDuration: 0.5,
            animations: { [weak self] in
                guard let self = self else {
                    return
                }
                self.tooltipView.alpha = 0
            },
            completion: { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.tooltipView.isHidden = true
            }
        )
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        detailTableView.delegate = self
        detailTableView.dataSource = self
        detailTableView.register(nibWithCellClass: DetailsViewTableCell.self)
        
        detailTableView.tableFooterView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: detailTableView.frame.size.width,
                height: 1
            )
        )
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    func showDetailPan() {
        detailView.layer.transform = rotateOut
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            options: [],
            animations: {
                self.faceView.layer.transform = self.rotateOut
            },
            completion: { _ in
                self.faceView.isHidden = true
                self.detailView.isHidden = false
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    options: [],
                    animations: {
                        self.detailView.layer.transform = self.rotateIn
                        self.contract?.position = .detail
                        self.delegate?.didSetNewPosition(for: self)
                        self.delegate?.didTapDetails(for: self)
                    }
                )
            }
        )
    }
    
    func hideDetailPan() {
        faceView.layer.transform = rotateOut
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            options: [],
            animations: {
                self.detailView.layer.transform = self.rotateOut
            },
            completion: { _ in
                self.detailView.isHidden = true
                self.faceView.isHidden = false
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    options: [],
                    animations: {
                        self.faceView.layer.transform = self.rotateIn
                        self.contract?.position = .face
                        self.delegate?.didSetNewPosition(for: self)
                    }
                )
            }
        )
    }
    
    func updateParentStatus(status: Bool) {
        contract?.parentStatus = status
        parentControlSwitch.isOn = (status == true)
    }
    
    func updateDetails(details: ContractDetailObject) {
        contract?.details = details
        
        let formatter = DateFormatter()

        formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd MMMM"

        detailRangeLabel.text = "c " + formatter.string(from: details.fromDay) +
                               " по " + formatter.string(from: details.toDay)

        detailTableView.reloadData()
    }
    
    func configureCell(_ contract: ContractFaceObject) {
        self.contract = contract
        contractNameLabel.text = contract.contractName
        addressLabel.text = contract.address
        let formattedBalance = contract.balance == 0 ? "0" : String(format: "%.0f", contract.balance)
        balanceLabel.text = formattedBalance + "₽"
        let limitDaysText: String = {
            guard let limitDays = contract.limitDays else {
                return ""
            }
            switch contract.limitDays {
            case 0, 5, 6, 7, 8, 9, 10:
                return " на " + String(limitDays) + " дней"
            case 1:
                return " на " + String(limitDays) + " день"
            case 2, 3, 4:
                return " на " + String(limitDays) + " дня"
            default:
                return ""
            }
        }()
        limitEnabledLabel.text = "подключен доверительный платеж" + limitDaysText
        limitEnabledLabel.isHidden = !contract.limitStatus
        paymentButtonTopConstraint.constant = contract.limitStatus ? 12 : 0
        
        if contract.services[.internet] == true, contract.parentEnable {
            parentControlView.isHidden = false
            parentControlSwitch.isEnabled = true
            parentControlSwitch.isOn = (contract.parentStatus == true)
        } else {
            parentControlView.isHidden = true
        }
        
        internetButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.internet.unselectedIcon,
            imageForSelected: SettingsServiceType.internet.selectedIcon
        )
        
        domophoneButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.domophone.unselectedIcon,
            imageForSelected: SettingsServiceType.domophone.selectedIcon
        )
        
        barrierButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.barrier.unselectedIcon,
            imageForSelected: SettingsServiceType.barrier.selectedIcon
        )

        monitorButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.iptv.unselectedIcon,
            imageForSelected: SettingsServiceType.iptv.selectedIcon
        )
        
        cctvButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.cctv.unselectedIcon,
            imageForSelected: SettingsServiceType.cctv.selectedIcon
        )
        
        kabelTVButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.ctv.unselectedIcon,
            imageForSelected: SettingsServiceType.ctv.selectedIcon
        )
        tooltipView.alpha = 0

        internetButton.isHidden = contract.services[.internet] == false
        domophoneButton.isHidden = contract.services[.domophone] == false
        barrierButton.isHidden = contract.services[.barrier] == false
        monitorButton.isHidden = contract.services[.iptv] == false
        cctvButton.isHidden = contract.services[.cctv] == false
        kabelTVButton.isHidden = contract.services[.ctv] == false

        internetButton.isSelected = contract.services[.internet] == true
        domophoneButton.isSelected = contract.services[.domophone] == true
        barrierButton.isSelected = contract.services[.barrier] == true
        monitorButton.isSelected = contract.services[.iptv] == true
        cctvButton.isSelected = contract.services[.cctv] == true
        kabelTVButton.isSelected = contract.services[.ctv] == true

        servicesExits = []
        tooltipCount = 0
        if contract.services[.ctv] == true {
            servicesExits.append(.ctv)
            tooltipCount += 1
        }
        if contract.services[.cctv] == true {
            servicesExits.append(.cctv)
            tooltipCount += 1
        }
        if contract.services[.domophone] == true {
            servicesExits.append(.domophone)
            tooltipCount += 1
        }
        if contract.services[.barrier] == true {
            servicesExits.append(.barrier)
            tooltipCount += 1
        }
        if contract.services[.iptv] == true {
            servicesExits.append(.iptv)
            tooltipCount += 1
        }
        if contract.services[.internet] == true {
            servicesExits.append(.internet)
            tooltipCount += 1
        }

        servicesStackView.spacing = {
            switch tooltipCount {
            case 4:
                return 8
            case let kt where kt > 4:
                return 6
            default:
                return 12
            }
        }()
        
        let limitAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "SourceSansPro-Regular", size: 14),
            .foregroundColor: UIColor(hex: 0x6D7A8A),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        let attributeString = NSMutableAttributedString(
            string: "Взять доверительный платеж",
            attributes: limitAttributes
        )
        limitButton.setAttributedTitle(attributeString, for: .normal)
        limitButton.isHidden = !contract.limitAvailable
        
        switch contract.position {
        case .face:
            faceView.layer.transform = rotateIn
            faceView.isHidden = false
            detailView.isHidden = true
        case .detail:
            detailView.layer.transform = rotateIn
            faceView.isHidden = true
            detailView.isHidden = false
        }
        
        let formatter = DateFormatter()

        formatter.timeZone = Calendar.novokuznetskCalendar.timeZone
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd MMMM"

        detailRangeLabel.text = "c " + formatter.string(from: contract.details.fromDay) +
                                " по " + formatter.string(from: contract.details.toDay)
        
        detailTableView.reloadData()
    }
}

extension ContractViewCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

extension ContractViewCell: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let contract = contract, !contract.details.details.isEmpty else {
            return 0
        }
        return contract.details.details.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let contract = contract, !contract.details.details.isEmpty else {
            return UITableViewCell()
        }
        let data = contract.details.details
        
        let cell = detailTableView.dequeueReusableCell(withClass: DetailsViewTableCell.self, for: indexPath)
        cell.configure(with: data[indexPath.row])
        
        return cell
    }
}
// swiftlint:enable function_body_length type_body_length
