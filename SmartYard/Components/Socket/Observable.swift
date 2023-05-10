//
//  Observable.swift
//  SmartYard
//
//  Created by devcentra on 02.05.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation

@objc
protocol ObservableProtocol: class { }

protocol ObservableSock {
    associatedtype Observer: ObservableProtocol
    
    var observers: [Observer] { get set }
    
    mutating func add(observer: Observer)
    mutating func remove(observer: Observer)
    func notifyObservers(_ block: (Observer) -> Void)
}

extension ObservableSock {
    mutating func add(observer: Observer) {
        if !self.observers.contains(where: { observer === $0 }) {
            self.observers.append(observer)
        }
    }
    mutating func remove(observer: Observer) {
        for (index, entry) in observers.enumerated()
        where entry === observer {
            observers.remove(at: index)
            return
        }
    }
    func notifyObservers(_ block: (Observer) -> Void) {
        observers.forEach { observer in
            block(observer)
        }
    }
}
