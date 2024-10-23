//
//  SelectProviderViewController.swift
//  SmartYard
//
//  Created by LanTa on 13.06.2022.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import JGProgressHUD
import RxCocoa
import RxSwift

final class SelectProviderViewController: BaseViewController, LoaderPresentable {
    
    @IBOutlet private weak var providerTextField: SmartYardTextField!
    @IBOutlet private weak var selectProviderButton: WhiteButtonWithBorder!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var fakeNavBar: FakeNavBar!
    
    var loader: JGProgressHUD?
    
    private let viewModel: SelectProviderViewModel
    
    private let itemsProxy = BehaviorSubject<[ProviderCellModel]>(value: [])
    private let itemStateChanged = PublishSubject<Int?>()
    
    init(viewModel: SelectProviderViewModel) {
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
        view.hideKeyboardWhenTapped = true
        selectProviderButton.titleLabel?.textAlignment = .center
        
        // providerTextField.text = ""
        providerTextField.sendActions(for: .allEditingEvents)
        
        tableView.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(nibWithCellClass: ProviderCell.self)
        
        tableView.tableFooterView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: tableView.frame.size.width,
                height: 1
            )
        )
        
        fakeNavBar.isHidden = true
    }
    
    private func bind() {
        let input = SelectProviderViewModel.Input(
            inputProviderName: providerTextField.rx.text.distinctUntilChanged().asDriver(onErrorJustReturn: nil),
            selectProviderTapped: selectProviderButton.rx.tap.asDriver(),
            itemStateChanged: itemStateChanged.asDriver(onErrorJustReturn: nil)
        )
        
        let output = viewModel.transform(input: input)
        
        output.providers
            .do(
                onNext: { [weak self] in
                    self?.tableView.isHidden = $0.isEmpty
                    self?.selectProviderButton.isEnabled = $0.contains { $0.state == .checkedActive }
                    
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

extension SelectProviderViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        itemStateChanged.onNext(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}

extension SelectProviderViewController: UITableViewDataSource {
    
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
        
        let cell = tableView.dequeueReusableCell(withClass: ProviderCell.self, for: indexPath)
        cell.configure(with: data[indexPath.row].provider.name, state: data[indexPath.row].state)
        
        return cell
    }
    
}
