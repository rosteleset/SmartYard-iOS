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

        // 2) preview tap index -> safe index
        let didTapPreviewIndex = input.events.didTapPreviewIndex
            .asObservable()
            .withLatestFrom(cameras) { index, cams -> Int? in
                guard !cams.isEmpty else { return nil }
                return min(max(index, 0), cams.count - 1)
            }
            .compactMap { $0 }

        // 3) preselected id -> index
        let preselectedIndex = Observable
            .combineLatest(preselectedId, cameras) { id, cams -> Int? in
                guard !cams.isEmpty else { return nil }
                return cams.firstIndex(where: { $0.id == id }) ?? 0
            }
            .compactMap { $0 }

        let preselectedSelection: Observable<(index: Int, source: OnlineSelectionSource)> = preselectedIndex
            .map { (index: $0, source: .preselected) }
        let mainCenteredSelection: Observable<(index: Int, source: OnlineSelectionSource)> = didCenterMainIndex
            .map { (index: $0, source: .mainCentered) }
        let previewTapSelection: Observable<(index: Int, source: OnlineSelectionSource)> = didTapPreviewIndex
            .map { (index: $0, source: .numberTap) }

        // Unified selection intents (index is the main currency)
        let selectionEvent: Observable<(index: Int, source: OnlineSelectionSource)> = Observable.merge(
            preselectedSelection,
            mainCenteredSelection,
            previewTapSelection
        )

        let selectionIntent: Observable<OnlineSelectionIntent> = selectionEvent
            .withLatestFrom(cameras) { pair, cams -> OnlineSelectionIntent? in
                guard !cams.isEmpty else { return nil }
                let clamped = min(max(pair.index, 0), cams.count - 1)
                let id = cams[clamped].id
                return OnlineSelectionIntent(index: clamped, cameraId: id, source: pair.source)
            }
            .compactMap { $0 }
            .distinctUntilChanged { $0.index == $1.index && $0.cameraId == $1.cameraId }
            .do(onNext: { intent in
                Logger.logDebug(
                    "selectionIntent id=\(intent.cameraId) index=\(intent.index) source=\(intent.source.logValue)"
                )
            })
            .share(replay: 1, scope: .whileConnected)

        let selectedCameraId: Observable<CameraID> = selectionIntent
            .map { $0.cameraId }
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)

        let selectedIndex: Observable<Int> = selectionIntent
            .map { $0.index }
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)

        let state = Observable
            .combineLatest(cameras, selectedCameraId, selectedIndex)
            .map { cams, selectedId, selectedIndex in
                OnlinePageState(
                    cameras: cams,
                    selectedCameraId: selectedId,
                    selectedIndex: selectedIndex
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
            selection: selectionIntent.asSignal(onErrorSignalWith: Signal<OnlineSelectionIntent>.empty())
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
