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
    
    @IBOutlet private weak var tableView: UITableView!
    
    private let disposeBag = DisposeBag()
    
    private let awakeFromNibSubject = PublishSubject<Void>()
    
    let sendSmsSubject = PublishSubject<Int?>()
    let deletePressedSubject = PublishSubject<Int?>()
    let addNewPersonSubject = PublishSubject<Void>()
    
    var viewModel = AccessViewModel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureTableView()
        bind()
        awakeFromNibSubject.onNext(())
    }
    
    private func bind() {
        viewModel.personsItemsSubject
            .subscribe(
                onNext: { [weak self] _ in
                    self?.tableView.reloadSections(
                        IndexSet(integer: 0),
                        with: .middle
                    )
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(nibWithCellClass: AllowedPersonCell.self)
        tableView.register(nibWithCellClass: NewPersonCell.self)
        
        tableView.tableFooterView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: tableView.frame.size.width,
                height: 1
            )
        )
    }
    
}

extension AccessView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let data = try? viewModel.personsItemsSubject.value() ,
            indexPath.row == data.count || data.isEmpty
        else {
            return 64
        }
    
        return 57
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let data = try? viewModel.personsItemsSubject.value() else {
            return false
        }
        
        return indexPath.row != data.count
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(
            style: .default,
            title: "Удалить"
        ) { [weak self] _, indexPath in
            self?.deletePressedSubject.onNext(indexPath.row)
            return
        }
        
        deleteButton.backgroundColor = UIColor.SmartYard.incorrectDataRed
        deleteButton.title = "Удалить"
        
        return [deleteButton]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let data = try? viewModel.personsItemsSubject.value() ,
              indexPath.row == data.count || data.isEmpty
        else {
            return
        }
        
        addNewPersonSubject.onNext(())
    }
    
}

extension AccessView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let data = try? viewModel.personsItemsSubject.value() else {
            return 0
        }
        
        return data.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let data = try? viewModel.personsItemsSubject.value() else {
            return UITableViewCell()
        }
        
        guard indexPath.row != data.count && !data.isEmpty else {
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
