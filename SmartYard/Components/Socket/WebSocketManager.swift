//
//  WebSocketManager.swift
//  SmartYard
//
//  Created by devcentra on 02.05.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import UIKit

@objc
protocol SocketObservable: ObservableProtocol {
    @objc
    func didConnect()
    
    @objc
    func didDiconnect()
    
    @objc
    func handleError(_ error: String)
    
    @objc
    optional func logSignal(_ signal: String?)
}

@available(iOS 13.0, *)
final class WebSocketManager: NSObject, ObservableSock {
    private enum NetworkEnvironment {
        case debug
        case master
    }
    
    static var shared = WebSocketManager()
    
    var observers: [SocketObservable] = []
    
    private let environment: NetworkEnvironment = .master
    private var session: URLSession!
    private var webSocketTask: URLSessionWebSocketTask!
    private var isConnected = false
    
    private var baseUrl: String {
        switch self.environment {
        case .debug: return Constants.socketDebugURL
        case .master: return Constants.socketMasterURL
        }
    }
    
    func connect() {
        guard !self.isConnected else {
            return
        }
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.webSocketTask = self.session.webSocketTask(with: URL(string: self.baseUrl)!)
        self.webSocketTask.resume()
    }
    
    func disconnect() {
        guard self.isConnected else {
            return
        }
        self.webSocketTask.cancel(with: .goingAway, reason: nil)
    }
    
    func sendSignal(message: String) {
        self.webSocketTask.send(.string(message)) { [weak self] error in
            guard let error = error else {
                return
            }
            self?.handleError(error.localizedDescription)
        }
    }
    
    private func connected() {
        self.notifyObservers { observers in
            observers.didConnect()
        }
        self.subscribe()
    }
    
    private func subscribe() {
        self.webSocketTask.receive { [weak self] result in
            switch result {
            case .failure(let error):
                self?.handleError("Failed to receive message: \(error.localizedDescription)")
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.logSignal("Receives text message: \(text)")
                case .data(let data):
                    print("Received binary message: \(data)")
                @unknown default:
                    fatalError("Socket data type cannot be processed")
                }
            }
        }
        self.subscribe()
    }
    
    private func disconnected() {
        self.notifyObservers { observers in
            observers.didDiconnect()
        }
    }
    
    private func handleError(_ errorMessage: String) {
        self.notifyObservers { observers in
            observers.handleError(errorMessage)
        }
    }
    
    private func logSignal(_ message: String?) {
        self.notifyObservers { observers in
            observers.logSignal?(message)
        }
    }
}

@available(iOS 13.0, *)
extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        self.isConnected = true
        self.connect()
    }
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.isConnected = false
        self.disconnect()
    }
}
