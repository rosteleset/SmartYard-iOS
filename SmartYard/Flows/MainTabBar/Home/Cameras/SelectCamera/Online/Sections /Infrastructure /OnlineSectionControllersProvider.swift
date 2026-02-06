//
//  OnlineSectionControllersProvider.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

typealias OnlineSectionController = AnySectionController<OnlineItem>

final class OnlineSectionControllersProvider {
    private let cameraController: OnlineSectionController
    private let numberController: OnlineSectionController

    init(
        playbackCoordinator: OnlinePlaybackCoordinating,
        events: OnlinePageEvents
    ) {
        cameraController = OnlineSectionController(
            CameraSectionController(
                events: events,
                playback: playbackCoordinator
            ),
            mapItem: { onlineItem in
                guard case let .camera(vm) = onlineItem else { return nil }
                return vm
            }
        )

        numberController = OnlineSectionController(
            CameraNumberSectionController(events: events),
            mapItem: { onlineItem in
                guard case let .number(vm) = onlineItem else { return nil }
                return vm
            }
        )
    }

    func controller(for section: OnlineSectionModel) -> OnlineSectionController {
        switch section.kind {
        case .cameraCarousel: return cameraController
        case .previewCarousel: return numberController
        }
    }
}

extension OnlineSectionControllersProvider {
    var allControllers: [OnlineSectionController] {
        return [cameraController, numberController]
    }
}
