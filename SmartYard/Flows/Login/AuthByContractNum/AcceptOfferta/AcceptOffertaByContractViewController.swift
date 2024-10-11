//
//  AcceptOffertaByContractViewController.swift
//  SmartYard
//
//  Created by devcentra on 16.02.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxViewController
import JGProgressHUD

class AcceptOffertaByContractViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var sendAcceptedOffers: BlueButton!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!

    private let itemsProxy = BehaviorSubject<[OffertaCellModel]>(value: [])
    private let itemStateChanged = PublishSubject<Int?>()
    private let itemShare = PublishSubject<Int?>()

    private let viewModel: AcceptOffertaByContractViewModel
    
    var loader: JGProgressHUD?
    
    init(viewModel: AcceptOffertaByContractViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fakeNavBar.configueBlueNavBar()
        configureView()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.isUserInteractionEnabled = true
    }
    
    private func configureView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(nibWithCellClass: OffertaCell.self)
        
        tableView.tableFooterView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: tableView.frame.size.width,
                height: 1
            )
        )
    }
    
    private func bind() {

        let input = AcceptOffertaByContractViewModel.Input(
            signInTapped: sendAcceptedOffers.rx.tap.asDriverOnErrorJustComplete(),
            itemStateChanged: itemStateChanged.asDriver(onErrorJustReturn: nil),
            itemShare: itemShare.asDriver(onErrorJustReturn: nil),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        let output = viewModel.transform(input: input)
        
        output.isAbleToProceed
            .drive(
                onNext: { [weak self] isAbleToProceed in
                    self?.sendAcceptedOffers.isEnabled = isAbleToProceed
                }
            )
            .disposed(by: disposeBag)

        output.offersModels
            .drive(
                onNext: { [weak self] offers in
                    self?.itemsProxy.onNext(offers)
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension AcceptOffertaByContractViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}

extension AcceptOffertaByContractViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let data = try? itemsProxy.value() else {
            return 0
        }
        
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let data = try? itemsProxy.value() else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withClass: OffertaCell.self, for: indexPath)
        cell.configure(with: data[indexPath.row].name, state: data[indexPath.row].state)
        cell.checkBox.tag = indexPath.row
        cell.offertaUrl.tag = indexPath.row
        cell.checkBox.addTarget(self, action: #selector(AcceptOffertaByContractViewController.offertaTaped(_:)), for: .touchUpInside)
        cell.offertaUrl.addTarget(self, action: #selector(AcceptOffertaByContractViewController.offertaDoc(_:)), for: .touchUpInside)

        return cell
    }
    
    @objc func offertaTaped(_ sender: UISwitch) {
        itemStateChanged.onNext(sender.tag)
    }
    
    @objc func offertaDoc(_ sender: UIButton) {
        itemShare.onNext(sender.tag)
    }
    
}
