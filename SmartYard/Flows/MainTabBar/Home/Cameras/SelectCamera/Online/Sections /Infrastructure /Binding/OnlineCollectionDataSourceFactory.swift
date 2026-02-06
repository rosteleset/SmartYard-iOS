//
//  OnlineCollectionDataSourceFactory.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxDataSources

enum OnlineCollectionDataSourceFactory {
    static func make(
        provider: OnlineSectionControllersProvider
    ) -> OnlineCollectionDataSource {

        return OnlineCollectionDataSource(
            animationConfiguration: AnimationConfiguration(
                insertAnimation: .none,
                reloadAnimation: .none,
                deleteAnimation: .none
            ),
            configureCell: { dataSource, collectionView, indexPath, item in
                let sectionModel = dataSource.sectionModels[indexPath.section]
                let controller = provider.controller(for: sectionModel)

                return controller.configureCell(
                    in: collectionView,
                    at: indexPath,
                    with: item
                )
            }
        )
    }
}
