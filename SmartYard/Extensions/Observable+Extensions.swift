//
//  Observable+Extensions.swift
//  SmartYard
//
//  Created by admin on 28/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public protocol OptionalType {
    
    associatedtype Wrapped
    
    var optional: Wrapped? { get }
    
}

extension Optional: OptionalType {
    
    public var optional: Wrapped? { return self }
    
}

extension ObservableType where Element == Bool {
    
    func not() -> Observable<Bool> {
        return self.map(!)
    }
    
}

extension SharedSequenceConvertibleType {
    
    func mapToVoid() -> SharedSequence<SharingStrategy, Void> {
        return map { _ in }
    }
    
    func mapToTrue() -> SharedSequence<SharingStrategy, Bool> {
        return map { _ in true }
    }
    
    func mapToFalse() -> SharedSequence<SharingStrategy, Bool> {
        return map { _ in false }
    }
}

extension SharedSequenceConvertibleType where Element == Bool {
    
    func not() -> SharedSequence<SharingStrategy, Bool> {
        return self.map(!)
    }
    
    func isTrue() -> SharedSequence<SharingStrategy, Bool> {
        return flatMap { isTrue in
            guard isTrue else {
                return SharedSequence<SharingStrategy, Bool>.empty()
            }
            return SharedSequence<SharingStrategy, Bool>.just(true)
        }
    }
    
    func filterFalse() -> SharedSequence<SharingStrategy, Bool> {
        return filter { !$0 }
    }
    
}

extension SharedSequenceConvertibleType where Element: OptionalType {
    
    func ignoreNil() -> SharedSequence<SharingStrategy, Element.Wrapped> {
        return flatMap { value in
            value.optional.map { .just($0) } ?? .empty()
        }
    }
    
}

extension ObservableType {
    
    func catchErrorJustComplete() -> Observable<Element> {
        return `catch` { _ in .empty() }
    }
    
    func asDriverOnErrorJustComplete() -> Driver<Element> {
        return asDriver { _ in .empty() }
    }
    
    func mapToVoid() -> Observable<Void> {
        return map { _ in }
    }
    
    func mapToTrue() -> Observable<Bool> {
        return map { _ in true }
    }
    
    func mapToFalse() -> Observable<Bool> {
        return map { _ in false }
    }
    
}

extension ObservableType where Element: OptionalType {
    
    func ignoreNil() -> Observable<Element.Wrapped> {
        return flatMap { value in
            value.optional.map { Observable.just($0) } ?? Observable.empty()
        }
    }
    
}

extension ObservableType where Element: Collection {
    
    func ignoreEmpty() -> Observable<Element> {
        return flatMap { array in
            array.isEmpty ? Observable.empty() : Observable.just(array)
        }
    }
    
}
