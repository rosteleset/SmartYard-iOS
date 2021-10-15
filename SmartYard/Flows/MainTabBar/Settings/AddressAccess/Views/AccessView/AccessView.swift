//
//  AddressAccessView.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import PMNibLinkableView
import RxDataSources

class AccessView: PMNibLinkableView {
    
    @IBOutlet private weak var tableView: UITableView!
    
    private let disposeBag = DisposeBag()
    
    private let awakeFromNibSubject = PublishSubject<Void>()
    
    private var dataSource: RxTableViewSectionedAnimatedDataSource<AllowedPersonSectionModel>?
    
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
        viewModel.sectionModels
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .map { [weak self] indexPath in
                self?.dataSource?[indexPath].identity
            }
            .ignoreNil()
            .filter { $0 == .addContact }
            .mapToVoid()
            .bind(to: addNewPersonSubject)
            .disposed(by: disposeBag)
    }
    
    // swiftlint:disable:next function_body_length
    private func configureTableView() {
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
        
        tableView.borderWidth = 1
        tableView.borderColor = UIColor.SmartYard.grayBorder
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<AllowedPersonSectionModel>(
            configureCell: { [weak self] _, tableView, indexPath, item in
                guard let self = self else {
                    // MARK: См. AddressesListViewController, почему нельзя просто вернуть UITableViewCell()
                    
                    return tableView.dequeueReusableCell(withClass: NewPersonCell.self, for: indexPath)
                }
                
                switch item {
                case .addContact:
                    let cell = tableView.dequeueReusableCell(withClass: NewPersonCell.self, for: indexPath)
                    return cell
                    
                case let .contact(person):
                    let cell = tableView.dequeueReusableCell(withClass: AllowedPersonCell.self, for: indexPath)
                    cell.configure(with: person)
                    
                    let subject = PublishSubject<Void>()
                    
                    subject
                        .map { indexPath.row }
                        .bind(to: self.sendSmsSubject)
                        .disposed(by: cell.disposeBag)
                    
                    cell.configureSMSButton(
                        isAvailable: person.roommateType == .outer,
                        subjectProxyIfAvailable: subject
                    )
                    
                    return cell
                }
            }
        )
        
        dataSource.canEditRowAtIndexPath = { dataSource, indexPath in
            if case let .contact(person) = dataSource[indexPath].identity, person.roommateType != .owner {
                return true
            } else {
                return false
            }
        }
        
        dataSource.animationConfiguration = AnimationConfiguration(
            insertAnimation: .fade,
            reloadAnimation: .fade,
            deleteAnimation: .fade
        )
        
        tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
        
        self.dataSource = dataSource
    }
    
}

extension AccessView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let item = dataSource?.sectionModels[safe: indexPath.section]?.items[safe: indexPath.row] else {
            return 0
        }
        
        switch item {
        case .addContact: return 57
        case .contact: return 64
        }
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
    
}
