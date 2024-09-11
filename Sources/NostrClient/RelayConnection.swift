//
//  RelayConnection.swift
//
//
//  Created by Jacob Davis on 3/26/24.
//

import Foundation
import Network
import Nostr

public class RelayConnection: NSObject {
    private(set) public var relayUrl: String
    var subscriptions: [Subscription]
    var webSocketTask: URLSessionWebSocketTask!
    var urlSession: URLSession!
    var delegate: RelayConnectionDelegate?
    var pingTimer: Timer?
    var networkMonitor: NWPathMonitor?
    var needsReconnect = false
    @Published private(set) public var connected = false
    
    public init?(relayUrl: String, subscriptions: [Subscription] = [], delegate: RelayConnectionDelegate? = nil) {
        guard let url = URL(string: relayUrl) else { return nil }
        self.relayUrl = relayUrl
        self.subscriptions = subscriptions
        self.delegate = delegate
        
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.webSocketTask = self.urlSession.webSocketTask(with: url)
    }
    
    public func connect() {
        if !connected {
            webSocketTask.resume()
            self.listen()
        }
    }
    
    public func disconnect() {
        if connected {
            self.unsubscribe()
            webSocketTask.cancel(with: .goingAway, reason: nil)
        }
    }
    
    func add(subscriptions: [Subscription]) {
        for sub in subscriptions {
            if let index = self.subscriptions.firstIndex(where: { $0.id == sub.id }) {
                if self.subscriptions[index] != sub {
                    self.subscriptions[index] = sub
                    self.subscribe(with: sub)
                }
            } else {
                self.subscriptions.append(sub)
                self.subscribe(with: sub)
            }
        }
    }
    
    func send(event: Event) {
        if connected {
            if let clientMessage = try? ClientMessage.event(event).string() {
                self.send(text: clientMessage)
            }
        }
    }
    
    func send(text: String) {
        if connected {
            self.webSocketTask.send(URLSessionWebSocketTask.Message.string(text)) { error in
                if let error {
                    print(error.localizedDescription)
                }
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
                                self.delegate?.didReceive(message: relayMessage, relayUrl: self.relayUrl)
                            }
                        @unknown default:
                            print("Uknown response")
                    }
                    self.listen()
                case .failure(let error):
                    print("NostrClient Error: \(self.relayUrl) " + error.localizedDescription)
            }
        }
    }
    
    private func setupNetworkMonitor() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                // Network is available again
                if ((self?.needsReconnect) != nil) {
                    if !(self?.connected ?? false) {
                        self?.connect()
                    }
                }
            } else {
                // Network is unavailable
                print("No network connection: Disconnected from relay: \(self?.relayUrl ?? "")")
                self?.needsReconnect = true
                self?.connected = false
                DispatchQueue.main.async {
                    self?.stopPing()
                }
                self?.delegate?.didDisconnect(relayUrl: self?.relayUrl ?? "")
            }
        }
        networkMonitor?.start(queue: DispatchQueue.global())
    }
    
    func startPing() {
        self.stopPing()
        self.pingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { [weak self] timer in
            if let connected = self?.connected, connected {
                self?.webSocketTask.sendPing(pongReceiveHandler: { error in
                    if let error {
                        print(error.localizedDescription)
                    }
                })
            }
        })
    }
    
    func stopPing() {
        self.pingTimer?.invalidate()
    }
    
    func subscribe() {
        for sub in self.subscriptions {
            subscribe(with: sub)
        }
    }
    
    func unsubscribe() {
        for sub in self.subscriptions {
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

public protocol RelayConnectionDelegate: AnyObject {
    func didReceive(message: RelayMessage, relayUrl: String)
    func didConnect(relayUrl: String)
    func didDisconnect(relayUrl: String)
}

extension  RelayConnection: URLSessionWebSocketDelegate {
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Connected to relay: \(self.relayUrl)")
        self.connected = true
        DispatchQueue.main.async {
            self.startPing()
        }
        self.subscribe()
        self.delegate?.didConnect(relayUrl: self.relayUrl)
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Disconnected from relay: \(self.relayUrl)")
        self.connected = false
        DispatchQueue.main.async {
            self.stopPing()
        }
        self.delegate?.didDisconnect(relayUrl: self.relayUrl)
    }
    
}
