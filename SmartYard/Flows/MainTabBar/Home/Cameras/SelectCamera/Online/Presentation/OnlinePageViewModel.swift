//
//  OnlinePageViewModel.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa

// MARK: - Selection Intent

struct OnlineSelectionIntent: Equatable {
    let index: Int
    let cameraId: CameraID
    let source: OnlineSelectionSource
}

final class OnlinePageViewModel: BaseViewModel {

    // MARK: - Public API

    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        let cameras = input.context.cameras
            .asObservable()
            .share(replay: 1, scope: .whileConnected)

        let preselectedId = input.context.preselectedCameraId
            .asObservable()
            .compactMap { $0 }
            .share(replay: 1, scope: .whileConnected)

        // 1) main centered index -> safe index
        let didCenterMainIndex = input.events.didCenterMainIndex
            .asObservable()
            .withLatestFrom(cameras) { index, cams -> Int? in
                guard !cams.isEmpty else { return nil }
                let clamped = min(max(index, 0), cams.count - 1)
                return clamped
            }
            .compactMap { $0 }

        // 2) preview tap id -> index
        let didTapPreviewIndex = input.events.didTapPreviewId
            .asObservable()
            .withLatestFrom(cameras) { id, cams -> Int? in
                cams.firstIndex(where: { $0.id == id })
            }
            .compactMap { $0 }

        // 3) preselected id -> index
        let preselectedIndex = Observable
            .combineLatest(preselectedId, cameras) { id, cams -> Int? in
                guard !cams.isEmpty else { return nil }
                return cams.firstIndex(where: { $0.id == id }) ?? 0
            }
            .compactMap { $0 }

        // Unified selection intents (index is the main currency)
        let selectionIntent = Observable.merge(
            preselectedIndex.map { (index: $0, source: OnlineSelectionSource.preselected) },
            didCenterMainIndex.map { (index: $0, source: OnlineSelectionSource.mainCentered) },
            didTapPreviewIndex.map { (index: $0, source: OnlineSelectionSource.numberTap) }
        )
            .withLatestFrom(cameras) { pair, cams -> OnlineSelectionIntent? in
                guard !cams.isEmpty else { return nil }
                let clamped = min(max(pair.index, 0), cams.count - 1)
                let id = cams[clamped].id
                return OnlineSelectionIntent(index: clamped, cameraId: id, source: pair.source)
            }
            .compactMap { $0 }
            .distinctUntilChanged { $0.cameraId == $1.cameraId }
            .do(onNext: { intent in
                Logger.logDebug(
                    "selectionIntent id=\(intent.cameraId) index=\(intent.index) source=\(intent.source.logValue)"
                )
            })
            .share(replay: 1, scope: .whileConnected)

        let selectedCameraId = selectionIntent
            .map(\.cameraId)
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)

        let state = Observable
            .combineLatest(cameras, selectedCameraId)
            .map { cams, selectedId in
                OnlinePageState(
                    cameras: cams,
                    selectedCameraId: selectedId
                )
            }
            .asDriverOnErrorJustComplete()

        let sections = cameras
            .map { [weak self] cams in
                self?.createSections(from: cams) ?? []
            }
            .asDriverOnErrorJustComplete()

        return Output(
            state: state,
            sections: sections,
            selection: selectionIntent.asSignal(onErrorSignalWith: .empty())
        )
    }

    func createSections(from cameras: [CameraViewModel]) -> [OnlineSectionModel] {
        guard !cameras.isEmpty else {
            Logger.logDebug("createSections empty cameras")
            return []
        }

        let cameraItems = cameras.map { OnlineItem.camera($0.cameraCell) }
        let numberItems = cameras.map { OnlineItem.number($0.numberCell) }

        return [
            OnlineSectionModel(kind: .cameraCarousel, items: cameraItems),
            OnlineSectionModel(kind: .previewCarousel, items: numberItems)
        ]
    }
}

// MARK: - Input / Output

extension OnlinePageViewModel {
    struct Input {
        let context: OnlinePageContext
        let events: OnlinePageEvents
    }

    struct Output {
        let state: Driver<OnlinePageState>
        let sections: Driver<[OnlineSectionModel]>
        let selection: Signal<OnlineSelectionIntent>
    }
}
