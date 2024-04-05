//
//  RelayConnection.swift
//
//
//  Created by Jacob Davis on 3/26/24.
//

import Foundation
import Nostr
import Starscream

public class RelayConnection {
    
    var relayDef: RelayDef
    var webSocket: WebSocket
    var isConnected: Bool
    var delegate: RelayConnectionDelegate?
    var subscriptionQueue: [Subscription] = []
    var subscriptionQueueTimer: Timer?
    
    public init?(relayDef: RelayDef, delegate: RelayConnectionDelegate? = nil) {
        self.relayDef = relayDef
        self.subscriptionQueue.append(contentsOf: self.relayDef.subscriptions)
        self.isConnected = false
        self.delegate = delegate
        guard let urlRequest = self.relayDef.urlRequest else { return nil }
        self.webSocket = WebSocket(request: urlRequest)
        self.webSocket.callbackQueue = DispatchQueue(label: self.relayDef.relayUrl, qos: .background) // TODO: Not sure about this
        self.webSocket.delegate = self
        self.startSubscriptionQueue()
    }
    
    func startSubscriptionQueue() {
        self.stopSubscriptionQueue()
        self.subscriptionQueueTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            if ((self?.isConnected) != nil) {
                if let subscriptionQueue = self?.subscriptionQueue {
                    for sub in subscriptionQueue {
                        if let clientMessage = try? ClientMessage.subscribe(sub).string() {
                            self?.webSocket.write(string: clientMessage)
                        }
                    }
                    self?.subscriptionQueue.removeAll()
                }
            }
        }
    }
    
    func stopSubscriptionQueue() {
        self.subscriptionQueueTimer?.invalidate()
    }
    
    public func add(subscriptions: [Subscription]) {
        self.relayDef.add(subscriptions: subscriptions)
        self.subscriptionQueue.append(contentsOf: subscriptions)
    }
    
    public func connect() {
        if !self.isConnected { self.webSocket.connect() }
    }
    
    public func disconnect() {
        if self.isConnected { self.webSocket.disconnect() }
    }

}

public protocol RelayConnectionDelegate: AnyObject {
    func didReceive(message: RelayMessage, relayUrl: String)
}

extension RelayConnection: WebSocketDelegate {
    
    public func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        
        switch event {
        case .connected(let headers):
                self.isConnected = true
                print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
                self.isConnected = false
                print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
                if let relayMessage = try? RelayMessage(text: string) {
                    self.delegate?.didReceive(message: relayMessage, relayUrl: self.relayDef.relayUrl)
                }
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
                print("PING")
            break
        case .pong(_):
                print("PONG")
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
                self.isConnected = false
        case .error(let error):
                print(error?.localizedDescription ?? "")
                self.isConnected = false
            //handleError(error)
        case .peerClosed:
            break
        }
        
    }
}

extension RelayConnection: Hashable {
    
    public static func == (lhs: RelayConnection, rhs: RelayConnection) -> Bool {
        lhs.relayDef == rhs.relayDef
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(relayDef.hashValue)
    }
    
}
