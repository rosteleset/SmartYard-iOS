//
//  APIStory.swift
//  SmartYard
//
//  Created by Codex on 21/05/2026.
//

struct APIStory: Decodable {

    let imageUrl: String
    let title: String
    let subtitle: String
    let url: String
    let presentMethod: APIStoryPresentMethod

    private enum CodingKeys: String, CodingKey {
        case imageUrl
        case imageURL
        case title
        case subtitle
        case url
        case presentMethod
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        subtitle = (try? container.decode(String.self, forKey: .subtitle)) ?? ""
        url = (try? container.decode(String.self, forKey: .url)) ?? ""
        imageUrl = (try? container.decode(String.self, forKey: .imageUrl))
            ?? (try? container.decode(String.self, forKey: .imageURL))
            ?? ""
        presentMethod = (try? container.decode(APIStoryPresentMethod.self, forKey: .presentMethod))
            ?? .webPopupController
    }
}

enum APIStoryPresentMethod: Decodable {
    case webPopupController
    case webViewController

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? ""
        let normalizedValue = rawValue
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }

        switch normalizedValue {
        case "webpopupcontroller", "webpopup", "popup":
            self = .webPopupController
        case "webviewcontroller", "webview":
            self = .webViewController
        default:
            self = .webPopupController
        }
    }
}
