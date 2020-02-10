//
//  ScrollableDataSource.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import RxDataSources

// swiftlint:disable all
class ScrollableDataSource<Section: AnimatableSectionModelType>: RxCollectionViewSectionedAnimatedDataSource<Section> {
    
    var dataSet = false
    
    let updatesFinishedSubject = PublishSubject<Void>()
    
    override func collectionView(_ collectionView: UICollectionView, observedEvent: Event<Element>) {
        Binder(self) { dataSource, newSections in
            guard dataSource.dataSet else {
                dataSource.dataSet = true
                dataSource.setSections(newSections)
                collectionView.reloadData()
                return
            }

            // if view is not in view hierarchy, performing batch updates will crash the app
            if collectionView.window == nil {
                dataSource.setSections(newSections)
                collectionView.reloadData()
                return
            }
            
            let oldSections = dataSource.sectionModels
            
            do {
                let differences = try Diff.differencesForSectionedView(initialSections: oldSections, finalSections: newSections)
                
                switch dataSource.decideViewTransition(dataSource, collectionView, differences) {
                case .animated:
                    // each difference must be run in a separate 'performBatchUpdates', otherwise it crashes.
                    // this is a limitation of Diff tool
                    
                    var counter = 0
                    
                    for difference in differences {
                        let updateBlock = {
                            // sections must be set within updateBlock in 'performBatchUpdates'
                            dataSource.setSections(difference.finalSections)
                            collectionView.batchUpdates(difference, animationConfiguration: dataSource.animationConfiguration)
                        }
                        
                        collectionView.performBatchUpdates(updateBlock) { [weak self] completed in
                            counter += 1
                            
                            if counter == differences.count {
                                self?.updatesFinishedSubject.onNext(())
                            }
                        }
                    }
                    
                case .reload:
                    dataSource.setSections(newSections)
                    collectionView.reloadData()
                    return
                }
            }
            catch let e {
                print("FATAL ERROR: \(e.localizedDescription)")
                dataSource.setSections(newSections)
                collectionView.reloadData()
            }
        }.on(observedEvent)
    }
    
}
// swiftlint:enable all
