//
//  StoryItem.swift
//  SmartYard
//
//  Created by Codex on 19/05/2026.
//

import Foundation

enum StoryItemPresentMethod: Equatable {
    case webPopupController
    case webViewController
}

struct StoryItem: Equatable {
    let imageUrl: String
    let title: String
    let subtitle: String
    let url: String
    let presentMethod: StoryItemPresentMethod
}

extension StoryItem {

    init(apiStory: APIStory) {
        imageUrl = apiStory.imageUrl
        title = apiStory.title
        subtitle = apiStory.subtitle
        url = apiStory.url

        switch apiStory.presentMethod {
        case .webPopupController:
            presentMethod = .webPopupController
        case .webViewController:
            presentMethod = .webViewController
        }
    }
}

struct StoryItemCellModel: Equatable {
    let imageUrl: String
    let title: String

    init(storyItem: StoryItem) {
        imageUrl = storyItem.imageUrl
        title = storyItem.title
    }
}
