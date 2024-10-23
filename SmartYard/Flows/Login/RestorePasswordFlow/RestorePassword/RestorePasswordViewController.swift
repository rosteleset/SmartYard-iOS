//
//  RestorePasswordViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 18.03.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import JGProgressHUD
import RxCocoa
import RxSwift

final class RestorePasswordViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var contractTextField: SmartYardTextField!
    @IBOutlet private weak var getCodeButton: WhiteButtonWithBorder!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var getRestoreMethodsButton: WhiteButtonWithBorder!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    var loader: JGProgressHUD?
    
    private let viewModel: RestorePasswordViewModel
    
    private let itemsProxy = BehaviorSubject<[RestoreMethodCellModel]>(value: [])
    private let itemStateChanged = PublishSubject<Int?>()
    
    private let preloadedContractNumber: String?
    
    init(viewModel: RestorePasswordViewModel, preloadedContractNumber: String?) {
        self.viewModel = viewModel
        self.preloadedContractNumber = preloadedContractNumber
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        bind()
    }

    private func configureUI() {
        view.hideKeyboardWhenTapped = true
        getRestoreMethodsButton.titleLabel?.textAlignment = .center
        
        contractTextField.text = preloadedContractNumber
        contractTextField.sendActions(for: .allEditingEvents)
        
        tableView.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(nibWithCellClass: RestoreMethodCell.self)
        
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
        let input = RestorePasswordViewModel.Input(
            inputContractNum: contractTextField.rx.text.distinctUntilChanged().asDriver(onErrorJustReturn: nil),
            getCodeButtonTapped: getCodeButton.rx.tap.asDriver(),
            itemStateChanged: itemStateChanged.asDriver(onErrorJustReturn: nil),
            getRestoreMethodsButtonTapped: getRestoreMethodsButton.rx.tap.asDriver(),
            backTrigger: fakeNavBar.rx.backButtonTap.asDriver()
        )
        
        contractTextField.rx.text.distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(
                onNext: { [weak self] text in
                    self?.getRestoreMethodsButton.isEnabled = !(text?.trimmed).isNilOrEmpty
                }
            )
            .disposed(by: disposeBag)
        
        let output = viewModel.transform(input: input)
        
        output.restoreMethods
            .do(
                onNext: { [weak self] in
                    self?.tableView.isHidden = $0.isEmpty
                    self?.getCodeButton.isHidden = $0.isEmpty
                    self?.getCodeButton.isEnabled = $0.contains { $0.state == .checkedActive }
                    self?.getRestoreMethodsButton.isHidden = !$0.isEmpty

                }
            )
            .drive(itemsProxy)
            .disposed(by: disposeBag)
        
        output.isLoading
            .debounce(.milliseconds(25))
            .drive(
                onNext: { [weak self] isLoading in
                    self?.updateLoader(isEnabled: isLoading, detailText: nil)
                }
            )
            .disposed(by: disposeBag)
        
        itemsProxy
            .subscribe(
                onNext: { [weak self] _ in
                    self?.tableView.reloadData()
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension RestorePasswordViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        itemStateChanged.onNext(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}

extension RestorePasswordViewController: UITableViewDataSource {
    
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
        
        let cell = tableView.dequeueReusableCell(withClass: RestoreMethodCell.self, for: indexPath)
        cell.configure(with: data[indexPath.row].method.displayedTextShouldSent, state: data[indexPath.row].state)
        
        return cell
    }
    
}
