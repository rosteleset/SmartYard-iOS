//
//  RequestSupportCallbackUseCase.swift
//  SmartYard
//
//  Created by Александр Попов on 04.03.2026.
//

import RxSwift

final class DefaultRequestSupportCallbackUseCase: RequestSupportCallbackUseCase {
    private let issueService: IssueService

    init(issueService: IssueService) {
        self.issueService = issueService
    }

    func execute() -> Single<Void> {
        issueService
            .sendCallbackIssue()
            .map { _ in () }
    }
}

protocol RequestSupportCallbackUseCase {
    func execute() -> Single<Void>
}
