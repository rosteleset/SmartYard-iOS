//
//  OnlineSectionModel.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 Sesameware. All rights reserved.
//

import RxDataSources

enum OnlineSectionKind: Hashable { case cameraCarousel, previewCarousel }

enum OnlineItem {
    case camera(CameraViewCellModel)
    case number(CameraNumberCellViewModel)
}

struct OnlineSectionModel {
    let kind: OnlineSectionKind
    var items: [OnlineItem]
}

extension OnlineItem: IdentifiableType, Equatable {
    typealias Identity = String

    var identity: String {
        switch self {
        case .camera(let model): return "camera_\(model.identity)"
        case .number(let model): return "number_\(model.identity)"
        }
    }

    static func == (lhs: OnlineItem, rhs: OnlineItem) -> Bool {
        switch (lhs, rhs) {
        case let (.camera(left), .camera(right)):
            return left == right
        case let (.number(left), .number(right)):
            return left == right
        default:
            return false
        }
    }
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
