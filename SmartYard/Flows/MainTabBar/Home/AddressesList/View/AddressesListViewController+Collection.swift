// Created by Александр Попов. Copyright © 2026 Sesameware.

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import JGProgressHUD
import SkeletonView
import SnapKit
import SwifterSwift

extension AddressesListViewController {
    func configureCollectionView() {
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        collectionView.refreshControl = refreshControl
        refreshControl.tintColor = UIColor.SmartYard.gray

        [
            AddressesListObjectCell.self,
            AddressesListCameraCell.self,
            AddressesListHistoryCell.self,
            AddressesListEmptyStateCell.self,
            UnapprovedObjectCell.self
        ].forEach {
            collectionView.register(nibWithCellClass: $0)
        }

        collectionView.register(cellWithClass: AddressesListDoorPreviewCell.self)
        collectionView.register(cellWithClass: AddressesListDoorPreviewPagerCell.self)
        collectionView.register(cellWithClass: AddressesListExtensionCell.self)
        collectionView.register(cellWithClass: AddressesHeaderCell.self)

        let dataSource = RxCollectionViewSectionedAnimatedDataSource<AddressesListSectionModel>(
            configureCell: { [weak self] _, collectionView, indexPath, item in
                guard let self = self else {
                    // MARK: я думал, мы сюда вообще никак не сможем попасть, но я еще никогда так не ошибался
                    // Из-за реактивщины этот датасорс может жить чуть дольше, чем этот контроллер
                    // Из-за того, что я возвращал UICollectionViewCell(), приложение падало с эксепшном
                    // Типа нельзя использовать ячейки без ReuseIdentifier в таком датасорсе
                    // Поэтому возвращаю рандомную ячейку. Все равно контроллер уже мертв, нам пофиг

                    return collectionView.dequeueReusableCell(
                        withClass: AddressesHeaderCell.self,
                        for: indexPath
                    )
                }

                return self.configureCell(
                    collectionView: collectionView,
                    indexPath: indexPath,
                    item: item
                )
            }
        )

        collectionView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)

        self.dataSource = dataSource
    }

    func configureCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        item: AddressesListDataItem
    ) -> UICollectionViewCell {
        if case .emptyState = item {
            let cell = collectionView.dequeueReusableCell(
                withClass: AddressesListEmptyStateCell.self,
                for: indexPath
            )
            cell.configure(with: .online)
            return cell
        }

        let customizableCell = makeBorderedCell(collectionView: collectionView, indexPath: indexPath, item: item)

        guard
            let itemsCountDict = try? itemsCountProxy.value(),
            let totalItemsInSection = itemsCountDict[indexPath.section]
        else {
            return customizableCell
        }

        let isFirstInSection = indexPath.row == 0
        let isLastInSection = indexPath.row == totalItemsInSection - 1

        customizableCell.addCustomBorder(
            isFirstInSection: isFirstInSection,
            isLastInSection: isLastInSection,
            customBorderWidth: 1,
            customBorderColor: UIColor.SmartYard.grayBorder,
            customlayerCornerRadius: 12
        )

        return customizableCell
    }

    // The switch keeps the reusable cell registration and configuration for each item together.
    // swiftlint:disable:next function_body_length
    private func makeBorderedCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        item: AddressesListDataItem
    ) -> CustomBorderCollectionViewCell {
        switch item {
        case let .header(_, address, isExpanded):
            let cell = collectionView.dequeueReusableCell(
                withClass: AddressesHeaderCell.self,
                for: indexPath
            )
            cell.configure(address: address, isExpanded: isExpanded)
            return cell

        case let .object(_, type, name, isOpened):
            let cell = collectionView.dequeueReusableCell(
                withClass: AddressesListObjectCell.self,
                for: indexPath
            )

            cell.configure(objectType: type, name: name, isOpened: isOpened)

            let subject = PublishSubject<Void>()

            subject
                .map { item.identity }
                .bind(to: self.requestGuestAccess)
                .disposed(by: cell.disposeBag)

            cell.bind(with: subject)

            return cell

        case let .doorPreviewPager(identity, items):
            let cell = collectionView.dequeueReusableCell(
                withClass: AddressesListDoorPreviewPagerCell.self,
                for: indexPath
            )

            cell.configure(
                items: items,
                selectedIdentity: self.selectedDoorPreviewIdentity(for: identity)
            )

            cell.openRequested
                .do(onNext: { [weak self] identity in
                    self?.rememberDoorPreviewIdentity(identity)
                })
                .bind(to: self.requestGuestAccess)
                .disposed(by: cell.disposeBag)

            cell.previewSelected
                .do(onNext: { [weak self] identity in
                    self?.rememberDoorPreviewIdentity(identity)
                })
                .bind(to: self.previewSelected)
                .disposed(by: cell.disposeBag)

            return cell

        case let .doorPreview(_, title, subtitle, previewSource, _, isOpened):
            let cell = collectionView.dequeueReusableCell(
                withClass: AddressesListDoorPreviewCell.self,
                for: indexPath
            )

            cell.configure(
                title: title,
                subtitle: subtitle,
                iconImageName: nil,
                previewSource: previewSource,
                isOpened: isOpened
            )

            let subject = PublishSubject<Void>()

            subject
                .map { item.identity }
                .bind(to: self.requestGuestAccess)
                .disposed(by: cell.disposeBag)

            cell.bind(with: subject)

            return cell

        case let .cameras(_, numberOfCameras):
            let cell = collectionView.dequeueReusableCell(
                withClass: AddressesListCameraCell.self,
                for: indexPath
            )
            cell.configure(availableCameras: numberOfCameras)
            return cell

        case let .history(_, eventsCount):
            let cell = collectionView.dequeueReusableCell(
                withClass: AddressesListHistoryCell.self,
                for: indexPath
            )
            cell.configure(itemsCount: eventsCount)
            return cell

        case let .extensionItem(_, caption, iconURL, isHighlighted):
            let cell = collectionView.dequeueReusableCell(
                withClass: AddressesListExtensionCell.self,
                for: indexPath
            )
            cell.configure(
                caption: caption,
                icon: UIImage(base64URLString: iconURL),
                isHighlighted: isHighlighted
            )
            return cell

        case let .unapprovedAddresses(_, address):
            let cell = collectionView.dequeueReusableCell(
                withClass: UnapprovedObjectCell.self,
                for: indexPath
            )
            cell.configure(address: address)
            cell.bind(with: qrCodeTapped)
            return cell

        case .emptyState: fatalError("Should be handled separately")
        case .offlineDoor: fatalError("Should be handled on the offline screen")
        }
    }
}

extension AddressesListViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if collectionView == storiesCollectionView {
            return CGSize(width: StoriesLayout.itemWidth, height: collectionView.bounds.height)
        }

        guard let item = dataSource?[indexPath] else { return .zero }

        switch item {
        case .emptyState:
            return CGSize(
                width: collectionView.width - 32,
                height: collectionView.bounds.height - 36
            )

        case let .header(_, address, _):
            let height = AddressesHeaderCell
                .preferredHeight(
                    for: UIScreen.main.bounds.width - 32,
                    title: address
                )
                .totalHeight

            return CGSize(
                width: UIScreen.main.bounds.width - 32,
                height: height
            )

        case .doorPreview, .doorPreviewPager:
            return CGSize(
                width: collectionView.width - 32,
                height: 176
            )

        default:
            return CGSize(
                width: collectionView.width - 32,
                height: 72
            )
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        if collectionView == storiesCollectionView {
            return StoriesLayout.lineSpacing
        }

        return 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        if collectionView == storiesCollectionView {
            return UIEdgeInsets(
                top: 0,
                left: StoriesLayout.horizontalInset,
                bottom: 0,
                right: StoriesLayout.horizontalInset
            )
        }

        let topInset: CGFloat = {
            switch section {
            case 0: return 16
            default: return 10
            }
        }()

        let bottomInset: CGFloat = {
            switch section {
            case collectionView.numberOfSections - 1: return 20
            default: return 0
            }
        }()

        return UIEdgeInsets(top: topInset, left: 16, bottom: bottomInset, right: 16)
    }

}

extension AddressesListViewController: UICollectionViewDragDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        guard
            indexPath.row == 0,
            let header = dataSource?[indexPath]
        else {
            return []
        }

        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return []
        }

        let renderer = UIGraphicsImageRenderer(bounds: cell.bounds)
        let image = renderer.image { cell.layer.render(in: $0.cgContext) }

        let snapshotView = UIImageView(image: image)
        snapshotView.frame = cell.frame
        snapshotView.layer.cornerRadius = 12
        snapshotView.clipsToBounds = true

        viewModel.collapseAllSections()
        collectionView.layoutIfNeeded()

        let provider = NSItemProvider(object: NSString())
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = header.identity
        dragItem.previewProvider = { UIDragPreview(view: snapshotView) }

        return [dragItem]
    }

}

extension AddressesListViewController: UICollectionViewDropDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: UICollectionViewDropCoordinator
    ) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }

        for wrapper in coordinator.items {
            guard
                let identity = wrapper.dragItem.localObject as? AddressesListDataItemIdentity,
                case .header = identity,
                let sourceIndexPath = wrapper.sourceIndexPath,
                sourceIndexPath.row == 0
            else { continue }

            viewModel.moveApprovedAddress(
                from: sourceIndexPath.section,
                to: destinationIndexPath.section
            )

            let target = IndexPath(item: 0, section: destinationIndexPath.section)
            coordinator.drop(wrapper.dragItem, toItemAt: target)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        if session.localDragSession != nil {
            return UICollectionViewDropProposal(
                operation: .move,
                intent: .insertAtDestinationIndexPath
            )
        } else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
    }

}
