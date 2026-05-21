//
//  GetStoriesRequest.swift
//  SmartYard
//
//  Created by Codex on 21/05/2026.
//

struct GetStoriesRequest {

    let accessToken: String
    let forceRefresh: Bool
}

extension GetStoriesRequest {

    var requestParameters: [String: Any] {
        return [:]
    }
}
