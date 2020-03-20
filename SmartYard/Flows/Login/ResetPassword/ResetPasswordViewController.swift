//
//  ResetPasswordViewController.swift
//  SmartYard
//
//  Created by Mad Brains on 18.03.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import JGProgressHUD
import RxCocoa
import RxSwift

class ResetPasswordViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var contractTextField: SmartYardTextField!
    @IBOutlet private weak var actionButton: WhiteButtonWithBorder!
    @IBOutlet private weak var methodsNotFoundLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    
    var loader: JGProgressHUD?
    
    let viewModel: ResetPasswordViewModel
    
    private let getResetMethodsText = "Получить доступные\nметоды восстановления"
    private let getResetCodeText = "Получить код восстановления"
    
    private let itemsProxy = BehaviorSubject<[ResetMethodModel]>(value: [])
    
    private let itemStateChanged = PublishSubject<Int?>()
    
    init(viewModel: ResetPasswordViewModel) {
        self.viewModel = viewModel
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
        tableView.isHidden = true
        methodsNotFoundLabel.isHidden = true
        
        view.hideKeyboardWhenTapped = true
        actionButton.titleLabel?.textAlignment = .center
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(nibWithCellClass: ResetMethodCell.self)
        
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
        let input = ResetPasswordViewModel.Input(
            inputContractNum: contractTextField.rx.text.distinctUntilChanged().asDriver(onErrorJustReturn: nil),
            actionTrigger: actionButton.rx.tap.asDriver(),
            itemStateChanged: itemStateChanged.asDriver(onErrorJustReturn: nil)
        )
        
        contractTextField.rx.text.distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(
                onNext: { [weak self] text in
                    self?.actionButton.isEnabled = !text.isNilOrEmpty
                }
            )
            .disposed(by: disposeBag)
        
        let output = viewModel.transform(input: input)
        
        output.resetMethods
            .do(
                onNext: { [weak self] in
                    guard $0.isEmpty else {
                        self?.tableView.isHidden = false
                        self?.methodsNotFoundLabel.isHidden = true
                        self?.actionButton.setTitle(self?.getResetCodeText, for: .normal)
                        self?.actionButton.isEnabled = false
                        return
                    }
                    
                    self?.tableView.isHidden = true
                    self?.methodsNotFoundLabel.isHidden = false
                    self?.actionButton.setTitle(self?.getResetMethodsText, for: .normal)
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

extension ResetPasswordViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        itemStateChanged.onNext(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}

extension ResetPasswordViewController: UITableViewDataSource {
    
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
        
        let cell = tableView.dequeueReusableCell(withClass: ResetMethodCell.self, for: indexPath)
        cell.configure(with: data[indexPath.row].type.displayedText, state: data[indexPath.row].state)
        
        return cell
    }
    
}
