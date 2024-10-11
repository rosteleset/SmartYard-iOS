//
//  TodayViewController.swift
//  LanTa
//
//  Created by Mad Brains on 08.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import UIKit
import NotificationCenter
import SmartYardSharedDataFramework
import RxSwift
import RxCocoa
import Intents

class WidgetViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var noObjectsLabel: UILabel!
    
    private let objectsData = BehaviorSubject<SmartYardSharedData?>(
        value: SmartYardSharedDataUtilities.loadSharedData()
    )

    private let areObjectsGrantAccessed = BehaviorSubject<[Int: Bool]>(value: [:])
    private let doorOpened = PublishSubject<Int?>()
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        configureTableView()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let updatedVisibleCellCount = numberOfTableRowsToDisplay()
        let currentVisibleCellCount = self.tableView.visibleCells.count
        let cellCountDifference = updatedVisibleCellCount - currentVisibleCellCount
        
        guard cellCountDifference != 0 else {
            return
        }
        
        coordinator.animate(
            alongsideTransition: { [weak self] _ in
                guard let self = self else {
                    return
                }
                
                let updateBlock = { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    // Васильев: иногда случается странный баг, что performBatchUpdates падает в Exception.
                    // связано это с тем, что currentVisibleCellCount при инициализации
                    // может вернуть тут 2 ячейки, а уже внутри updateBlock - 3 ячейки
                    // поэтому проверку приходится делать ещё раз - да, это костыль.
                    let currentVisibleCellCount = self.tableView.visibleCells.count
                    let cellCountDifference = updatedVisibleCellCount - currentVisibleCellCount
                    
                    guard cellCountDifference != 0 else {
                        return
                    }
                    
                    let range = (1...abs(cellCountDifference))
                    let indexPaths = range.map { IndexPath(row: $0, section: 0) }
                    
                    if cellCountDifference > 0 {
                        self.tableView.insertRows(at: indexPaths, with: .fade)
                    } else {
                        self.tableView.deleteRows(at: indexPaths, with: .fade)
                    }
                }
                
                self.tableView.performBatchUpdates(updateBlock, completion: nil)
            },
            completion: nil
        )
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        guard let data = try? objectsData.value() else {
            return
        }
        
        switch activeDisplayMode {
        case .compact:
            preferredContentSize = CGSize(width: maxSize.width, height: WdgObjectCell.defaultHeight)
            
        case .expanded:
            let bottomOffset: CGFloat = 10
            let totalHeight = CGFloat(data.sharedObjects.count) * WdgObjectCell.defaultHeight + bottomOffset
            preferredContentSize = CGSize(width: maxSize.width, height: min(totalHeight, maxSize.height))
            
        @unknown default:
            break
        }
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        objectsData.onNext(SmartYardSharedDataUtilities.loadSharedData())
        completionHandler(NCUpdateResult.newData)
    }
    
    fileprivate func numberOfTableRowsToDisplay() -> Int {
        guard let totalCount = try? objectsData.value()?.sharedObjects.count else {
            return 0
        }
        
        return extensionContext?.widgetActiveDisplayMode == NCWidgetDisplayMode.compact ? 1 : totalCount
    }

    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        let cellNib = UINib(nibName: "WdgObjectCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: WdgObjectCell.reuseIdentifier)
        
        tableView.tableFooterView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: tableView.frame.size.width,
                height: 1
            )
        )
    }
    
    private func closeObjectAccessAfterTimeout(index: Int) {
        Timer.scheduledTimer(
            withTimeInterval: 5,
            repeats: false
        ) { [weak self] _ in
            guard let self = self, let data = try? self.areObjectsGrantAccessed.value() else {
                return
            }
            
            var newDict = data
            newDict[index] = false
            
            self.areObjectsGrantAccessed.onNext(newDict)
        }
    }
    
    private func bind() {
        objectsData.asDriver(onErrorJustReturn: nil)
            .drive(
                onNext: { [weak self] objects in
                    var accessStateDict = [Int: Bool]()
                    
                    objects?.sharedObjects.enumerated().forEach { offset, _ in
                        accessStateDict[offset] = false
                    }
                    
                    self?.areObjectsGrantAccessed.onNext(accessStateDict)
                    self?.noObjectsLabel.isHidden = !accessStateDict.isEmpty
                    self?.tableView.isHidden = accessStateDict.isEmpty
                }
            )
            .disposed(by: disposeBag)
        
        areObjectsGrantAccessed.asDriver(onErrorJustReturn: [:])
            .drive(
                onNext: { [weak self] _ in
                    self?.tableView.reloadData()
                }
            )
            .disposed(by: disposeBag)
        
        doorOpened.asDriver(onErrorJustReturn: nil)
            .withLatestFrom(areObjectsGrantAccessed.asDriver(onErrorJustReturn: [:])) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (index, statesArr) = args
                    guard let doorIndex = index else {
                        return
                    }
                    
                    var newDict = statesArr
                    newDict[doorIndex] = true
                    
                    self?.areObjectsGrantAccessed.onNext(newDict)
                    self?.closeObjectAccessAfterTimeout(index: doorIndex)
                }
            )
            .disposed(by: disposeBag)
        
        doorOpened.asDriver(onErrorJustReturn: nil)
            .withLatestFrom(objectsData.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .drive(
                onNext: { args in
                    let (index, object) = args
                    
                    guard let uIndex = index, let uObject = object else {
                        return
                    }
                    
                    let curObject = uObject.sharedObjects[uIndex]
                    
                    SmartYardSharedDataUtilities.sendOpenDoorRequest(
                        accessToken: uObject.accessToken,
                        backendURL: uObject.backendURL ?? Constants.defaultBackendURL,
                        doorId: curObject.doorId,
                        domophoneId: curObject.domophoneId
                    )
                    
                    SmartYardSharedFunctions.donateInteraction(curObject)
                }
            )
            .disposed(by: disposeBag)
    }
    
}

extension WidgetViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        WdgObjectCell.defaultHeight
    }
    
}

extension WidgetViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        numberOfTableRowsToDisplay()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let data = try? objectsData.value(),
              let stateData = try? areObjectsGrantAccessed.value(),
              let cell = tableView
                .dequeueReusableCell(
                    withIdentifier: WdgObjectCell.reuseIdentifier,
                    for: indexPath
                ) as? WdgObjectCell
        else {
            return UITableViewCell()
        }
        
        cell.configure(with: data.sharedObjects[indexPath.row], isOpened: stateData[indexPath.row] ?? false)
        
        let subject = PublishSubject<Void>()
        
        subject
            .map { indexPath.row }
            .bind(to: self.doorOpened)
            .disposed(by: cell.disposeBag)
        
        cell.bind(with: subject)
        
        return cell
    }
    
}
// swiftlint:enable function_body_length
