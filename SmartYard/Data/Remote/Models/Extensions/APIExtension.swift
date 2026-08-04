//
//  APIExtension.swift
//  SmartYard
//
//  Created by Александр Васильев on 15.03.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

import Foundation
import UIKit

struct APIExtension: Decodable {
    
    let basePath: String
    let contentHTML: String
    let version: Int
    let webViewOptions: WebViewOptions?
    
    private enum CodingKeys: String, CodingKey {
        case basePath
        case code
        case version
        case webViewOptions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        basePath = try container.decode(String.self, forKey: .basePath)
        contentHTML = try container.decode(String.self, forKey: .code)
        version = (try? container.decode(Int.self, forKey: .version)) ?? 1
        webViewOptions = try? container.decode(WebViewOptions.self, forKey: .webViewOptions)
    }

    struct WebViewOptions: Decodable {

        let navBarHidden: Bool?
        let statusBarColor: String?
        let statusBarStyle: StatusBarStyle?
        let navBarColor: String?
        let navBarContentColor: String?
        let tabBarHidden: Bool?
        let extendsUnderTabBar: Bool?
        let pullToRefreshEnabled: Bool?

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case navBarHidden
            case statusBarColor
            case statusBarStyle
            case navBarColor
            case navBarContentColor
            case tabBarHidden
            case extendsUnderTabBar
            case pullToRefreshEnabled
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            navBarHidden = try? container.decode(Bool.self, forKey: .navBarHidden)
            statusBarColor = try? container.decode(String.self, forKey: .statusBarColor)
            statusBarStyle = try? container.decode(StatusBarStyle.self, forKey: .statusBarStyle)
            navBarColor = try? container.decode(String.self, forKey: .navBarColor)
            navBarContentColor = try? container.decode(String.self, forKey: .navBarContentColor)
            tabBarHidden = try? container.decode(Bool.self, forKey: .tabBarHidden)
            extendsUnderTabBar = try? container.decode(Bool.self, forKey: .extendsUnderTabBar)
            pullToRefreshEnabled = try? container.decode(Bool.self, forKey: .pullToRefreshEnabled)
        }

        init(
            navBarHidden: Bool? = nil,
            statusBarColor: String? = nil,
            statusBarStyle: StatusBarStyle? = nil,
            navBarColor: String? = nil,
            navBarContentColor: String? = nil,
            tabBarHidden: Bool? = nil,
            extendsUnderTabBar: Bool? = nil,
            pullToRefreshEnabled: Bool? = nil
        ) {
            self.navBarHidden = navBarHidden
            self.statusBarColor = statusBarColor
            self.statusBarStyle = statusBarStyle
            self.navBarColor = navBarColor
            self.navBarContentColor = navBarContentColor
            self.tabBarHidden = tabBarHidden
            self.extendsUnderTabBar = extendsUnderTabBar
            self.pullToRefreshEnabled = pullToRefreshEnabled
        }
    }

    enum StatusBarStyle: String, Decodable {
        case dark
        case light
    }
}
