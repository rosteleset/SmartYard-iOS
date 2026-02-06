//
//  OnlineSectionModel.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxDataSources

enum OnlineSectionKind: Hashable { case cameraCarousel, previewCarousel }

enum OnlineItem {
    case camera(CameraViewCellModel)
    case number(CameraNumberCellViewModel)
}

extension OnlineItem: IdentifiableType, Equatable {
    typealias Identity = String

    var identity: String {
        switch self {
        case .camera(let model): return "camera_\(model.id)"
        case .number(let model): return "number_\(model.cameraId)"
        }
    }

    static func == (lhs: OnlineItem, rhs: OnlineItem) -> Bool {
        switch (lhs, rhs) {
        case (.camera(let left), .camera(let right)):
            return left == right
        case (.number(let left), .number(let right)):
            return left == right
        default:
            return false
        }
    }
}

struct OnlineSectionModel {
    let kind: OnlineSectionKind
    var items: [OnlineItem]
}

extension OnlineSectionModel: AnimatableSectionModelType {
    typealias Item = OnlineItem
    typealias Identity = OnlineSectionKind

    var identity: OnlineSectionKind {
        return kind
    }

    init(original: OnlineSectionModel, items: [OnlineItem]) {
        self = original
        self.items = items
    }
}
