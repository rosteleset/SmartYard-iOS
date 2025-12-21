//
//  APIWrapper.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Moya
import Alamofire
import RxSwift
import RxCocoa
import FirebaseCrashlytics

final class APIWrapper {
    let internet: InternetMonitoring
    let backend: BackendMonitoring
    let accessService: AccessService
    let provider: MoyaProvider<APITarget>

    var forceUpdateFaces = false
    var forceUpdateSettings = false
    var forceUpdateAddress = false
    var forceUpdatePayments = false
    var forceUpdateIssues = false

    init(
        accessService: AccessService = .shared,
        session: Session,
        internet: InternetMonitoring,
        backend: BackendMonitoring
    ) {
        self.accessService = accessService
        self.provider = MoyaProvider<APITarget>(session: session)
        self.internet = internet
        self.backend = backend
    }
}
