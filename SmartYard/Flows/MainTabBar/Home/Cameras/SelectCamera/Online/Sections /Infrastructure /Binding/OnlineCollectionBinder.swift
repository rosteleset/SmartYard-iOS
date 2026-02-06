//
//  OnlineCollectionBinder.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxCocoa
import RxRelay
import RxSwift
import UIKit

final class OnlineCollectionBinder: HasDisposeBag {
    typealias MakeDataSource = CollectionMakeDataSource<
        OnlineSectionControllersProvider,
        OnlineCollectionDataSource
    >

    // MARK: - Dependencies

    private let provider: OnlineSectionControllersProvider
    private let makeDataSource: MakeDataSource

    // MARK: - State

    private let latestSection = BehaviorRelay<[OnlineSectionModel]>(value: [])

    /// Хук, чтобы внешний слой (SelectionNavigator) мог знать “секции обновились”.
    var onSectionsUpdated: (([OnlineSectionModel]) -> Void)?

    // MARK: - Init

    init(
        provider: OnlineSectionControllersProvider,
        makeDataSource: @escaping MakeDataSource = OnlineCollectionDataSourceFactory.make
    ) {
        self.provider = provider
        self.makeDataSource = makeDataSource
    }

    // MARK: - Bind

    func bind(
        collectionView: UICollectionView,
        sections: Driver<[OnlineSectionModel]>
    ) {
        Logger.logDebug("bind")
        registerCells(in: collectionView)

        let dataSource = makeDataSource(provider)

        bindSections(sections, to: collectionView, dataSource: dataSource)
        bindCollectionEvents(from: collectionView)
    }
}

// MARK: - Private

private extension OnlineCollectionBinder {

    // MARK: - Registration

    func registerCells(in collectionView: UICollectionView) {
        provider.allControllers.forEach { $0.registerCells(in: collectionView) }
    }

    // MARK: - Sections -> Collection

    func bindSections(
        _ sections: Driver<[OnlineSectionModel]>,
        to collectionView: UICollectionView,
        dataSource: OnlineCollectionDataSource
    ) {
        sections
            .do { [weak self] sections in
                self?.latestSection.accept(sections)
                self?.onSectionsUpdated?(sections)
                Logger.logDebug("sections updated count=\(sections.count)")
            }
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }

    // MARK: - Events -> SectionControllers

    func bindCollectionEvents(from collectionView: UICollectionView) {

        // 1) didSelect
        collectionView.rx.itemSelected
            .withLatestFrom(latestSection) { ($0, $1) }
            .subscribe(onNext: { [weak self] indexPath, sections in
                guard let self else { return }
                guard let (section, item) = resolve(sections, indexPath) else { return }

                let controller = provider.controller(for: section)
                controller.didSelect(screenItem: item, at: indexPath)
            })
            .disposed(by: disposeBag)

        // 2) willDisplay
        collectionView.rx.willDisplayCell
            .withLatestFrom(latestSection, resultSelector: { event, sections in
                (event.cell, event.at, sections)
            })
            .subscribe(onNext: { [weak self] cell, indexPath, sections in
                guard let self else { return }
                guard let (section, item) = resolve(sections, indexPath) else { return }

                let controller = provider.controller(for: section)
                controller.willDisplay(cell, at: indexPath, for: item)
            })
            .disposed(by: disposeBag)

        // 3) didEndDisplaying
        collectionView.rx.didEndDisplayingCell
            .withLatestFrom(latestSection) { event, sections in
                (event.cell, event.at, sections)
            }
            .subscribe(onNext: { [weak self] cell, indexPath, sections in
                guard let self else { return }
                guard let (section, item) = resolve(sections, indexPath) else { return }

                let controller = provider.controller(for: section)
                controller.didEndDisplay(cell, at: indexPath, for: item)
            })
            .disposed(by: disposeBag)

        // 4) prefetch
        collectionView.rx.prefetchItems
            .withLatestFrom(latestSection) { ($0, $1) }
            .subscribe(onNext: { [weak self] indexPaths, sections in
                guard let self else { return }

                for indexPath in indexPaths {
                    guard let (section, item) = resolve(sections, indexPath) else { continue }
                    let controller = provider.controller(for: section)
                    controller.prefetch(screenItems: [item])
                }
            })
            .disposed(by: disposeBag)

        // 5) cancelPrefetch
        collectionView.rx.cancelPrefetchingForItems
            .withLatestFrom(latestSection) { ($0, $1) }
            .subscribe(onNext: { [weak self] indexPaths, sections in
                guard let self else { return }

                for indexPath in indexPaths {
                    guard let (section, item) = resolve(sections, indexPath) else { continue }
                    let controller = provider.controller(for: section)
                    controller.cancelPrefetch(screenItems: [item])
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Resolve

    func resolve(
        _ sections: [OnlineSectionModel],
        _ indexPath: IndexPath
    ) -> (OnlineSectionModel, OnlineItem)? {
        guard sections.indices.contains(indexPath.section) else {
            Logger.logDebug(
                "resolve outOfBounds section=\(indexPath.section) sections=\(sections.count)"
            )
            return nil
        }
        let section = sections[indexPath.section]
        guard section.items.indices.contains(indexPath.item) else {
            Logger.logDebug("resolve outOfBounds item=\(indexPath.item) items=\(section.items.count)")
            return nil
        }
        let item = section.items[indexPath.item]
        return (section, item)
    }
}
