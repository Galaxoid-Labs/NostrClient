//
//  RelayConnection.swift
//
//
//  Created by Jacob Davis on 3/26/24.
//

import Foundation
import Nostr

public protocol RelayDefinition {
    var relayUrl: String { get }
    var write: Bool { get set }
    var subscriptions: [Subscription] { get set }
    var urlRequest: URL? { get }
}

public protocol RelayConnectionDelegate: AnyObject {
    func didReceive(message: RelayMessage, relayUrl: String)
}

public class RelayConnection: NSObject {
    var relayDefinition: RelayDefinition
    var webSocketTask: URLSessionWebSocketTask!
    var urlSession: URLSession!
    var delegate: RelayConnectionDelegate?
    var pingTimer: Timer?
    var connected = false
    
    public init?(relayDefinition: RelayDefinition, delegate: RelayConnectionDelegate? = nil) {
        guard let url = relayDefinition.urlRequest else { return nil }
        
        self.relayDefinition = relayDefinition
        
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.webSocketTask = self.urlSession.webSocketTask(with: url)
    }
    
    public func connect() {
        webSocketTask.resume()
        self.listen()
    }
    
    public func disconnect() {
        self.unsubscribe()
        webSocketTask.cancel(with: .goingAway, reason: nil)
    }
    
    func add(subscriptions: [Subscription]) {
        for sub in subscriptions {
            if let index = self.relayDefinition.subscriptions.firstIndex(where: { $0.id == sub.id }) {
                self.relayDefinition.subscriptions[index] = sub
                self.subscribe(with: sub)
            } else {
                self.relayDefinition.subscriptions.append(sub)
                self.subscribe(with: sub)
            }
        }
    }
    
    func send(event: Event) {
        if let clientMessage = try? ClientMessage.event(event).string() {
            self.send(text: clientMessage)
        }
    }
    
    func send(text: String) {
        self.webSocketTask.send(URLSessionWebSocketTask.Message.string(text)) { error in
            if let error {
                print(error.localizedDescription)
            }
        }
    }
    
    func listen() {
        webSocketTask.receive { result in
            switch result {
                case .success(let message):
                    switch message {
                        case .data(_): break
                        case .string(let text):
                            if let relayMessage = try? RelayMessage(text: text) {
                                self.delegate?.didReceive(message: relayMessage, relayUrl: self.relayDefinition.relayUrl)
                            }
                        @unknown default:
                            print("Uknown response")
                    }
                    self.listen()
                case .failure(let error):
                    print("NostrClient Error: \(self.relayDefinition.relayUrl)" + error.localizedDescription)
            }
        }
    }
    
    func startPing() {
        self.stopPing()
        self.pingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { [weak self] timer in
            self?.webSocketTask.sendPing(pongReceiveHandler: { error in
                if let error {
                    print(error.localizedDescription)
                }
            })
        })
    }
    
    func stopPing() {
        self.pingTimer?.invalidate()
    }
    
    func subscribe() {
        for sub in relayDefinition.subscriptions {
            subscribe(with: sub)
        }
    }
    
    func unsubscribe() {
        for sub in relayDefinition.subscriptions {
            unsubscribe(withId: sub.id)
        }
    }
    
    func unsubscribe(withId id: String) {
        if connected {
            if let clientMessage = try? ClientMessage.unsubscribe(id).string() {
                self.send(text: clientMessage)
            }
        }
    }
        
    func subscribe(with subscription: Subscription) {
        if connected {
            if let clientMessage = try? ClientMessage.subscribe(subscription).string() {
                self.send(text: clientMessage)
            }
        }
    }
    
}

extension  RelayConnection: URLSessionWebSocketDelegate {
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("\(self.relayDefinition.relayUrl) did open")
        self.connected = true
        self.startPing()
        self.subscribe()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("\(self.relayDefinition.relayUrl) did close")
        self.connected = false
        self.stopPing()
    }
    
}


