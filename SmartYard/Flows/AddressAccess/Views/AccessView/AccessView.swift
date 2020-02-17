//
//  AddressAccessView.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import PMNibLinkableView

class AccessView: PMNibLinkableView {
    
    @IBOutlet private weak var containerView: FullRoundedView!
    @IBOutlet private weak var tableView: UITableView!
    
    private let itemsProxy = BehaviorSubject<[AllowedPerson]>(value: [])
    private let disposeBag = DisposeBag()
    
    private let awakeFromNibSubject = PublishSubject<Void>()
    
    let sendSmsSubject = PublishSubject<Int?>()
    let deletePressedSubject = PublishSubject<Int?>()
    let addNewPersonSubject = PublishSubject<Void>()
    
    var viewModel: AccessViewModel? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureTableView()
        awakeFromNibSubject.onNext(())
    }
    
    private func bind() {
        let input = AccessViewModel.Input(
            deletePressedTrigger: deletePressedSubject.asDriver(onErrorJustReturn: nil),
            addNewPersonTrigger: addNewPersonSubject.asDriverOnErrorJustComplete(),
            awakeFromNibTrigger: awakeFromNibSubject.asDriverOnErrorJustComplete()
        )
        
        guard let output = viewModel?.transform(input: input) else {
            return
        }
        
        output.personsTrigger
            .drive(itemsProxy)
            .disposed(by: disposeBag)
        
        itemsProxy
            .subscribe(
                onNext: { [weak self] _ in
                    self?.tableView.reloadData()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(nibWithCellClass: AllowedPersonCell.self)
        tableView.register(nibWithCellClass: NewPersonCell.self)
    }
    
}

extension AccessView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let data = try? itemsProxy.value() else {
            return false
        }
        
        return indexPath.row != data.count + 1 || !data.isEmpty
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(
            style: .default,
            title: "Удалить"
        ) { [weak self] _, indexPath in
            print("Delete pressed")
            tableView.beginUpdates()
            self?.deletePressedSubject.onNext(indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            tableView.endUpdates()
            
            return
        }
        
        deleteButton.backgroundColor = UIColor.SmartYard.incorrectDataRed
        deleteButton.title = "Удалить"
        
        return [deleteButton]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let data = try? itemsProxy.value() ,
              indexPath.row == data.count + 1 || data.isEmpty
        else {
            return
        }
        
        addNewPersonSubject.onNext(())
    }
    
}

extension AccessView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let data = try? itemsProxy.value() else {
            return 0
        }
        
        return data.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let data = try? itemsProxy.value() else {
            return UITableViewCell()
        }
        
        guard indexPath.row != data.count + 1 && !data.isEmpty else {
            let cell = tableView.dequeueReusableCell(withClass: NewPersonCell.self, for: indexPath)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withClass: AllowedPersonCell.self, for: indexPath)
        cell.configure(with: data[indexPath.row])
        
        let subject = PublishSubject<Void>()
        
        subject
            .map { indexPath.row }
            .bind(to: sendSmsSubject)
            .disposed(by: cell.disposeBag)
        
        cell.bind(with: subject)
        
        return cell
    }
    
}
