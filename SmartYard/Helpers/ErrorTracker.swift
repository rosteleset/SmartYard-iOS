//
//  ErrorTracker.swift
//  SmartYard
//
//  Created by admin on 17/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import FirebaseCrashlytics

final class ErrorTracker: SharedSequenceConvertibleType {
    
    typealias SharingStrategy = DriverSharingStrategy
    
    private let _subject = PublishSubject<Error>()
    
    deinit {
        _subject.onCompleted()
    }
    
    func trackError<O: ObservableConvertibleType>(from source: O) -> Observable<O.Element> {
        return source.asObservable().do(onError: onError)
    }
    
    func asSharedSequence() -> SharedSequence<SharingStrategy, Error> {
        return _subject.asObservable().asDriverOnErrorJustComplete()
    }
    
    func asObservable() -> Observable<Error> {
        return _subject.asObservable()
    }
    
    func onError(_ error: Error) {
        Crashlytics.crashlytics().record(error: error)
        _subject.onNext(error)
    }
    
}

extension ObservableConvertibleType {
    
    func trackError(_ errorTracker: ErrorTracker) -> Observable<Element> {
        return errorTracker.trackError(from: self)
    }
    
}

extension SharedSequenceConvertibleType where Element == Error {
    
    func catchAuthorizationError(block: @escaping () -> Void) -> SharedSequence<SharingStrategy, Element?> {
        return map { error -> Error? in
            let nsError = error as NSError
            
            guard nsError.code == 401 else {
                return error
            }
            
            block()
            
            return nil
        }
    }
    
}
