import Foundation
import Nostr

public class NostrClient: ObservableObject {
    
    public init() {}

    @Published private(set) public var relayConnections: [RelayConnection] = []
    public var delegate: NostrClientDelegate?
    
    public func sendEvent(event: Event, onlyToRelayUrls relayUrls: [String]? = nil) {
        if let relayUrls = relayUrls {
            for url in relayUrls {
                if let indexOf = self.relayConnections.firstIndex(where: { $0.relayDefinition.relayUrl == url }) {
                    self.relayConnections[indexOf].send(event: event)
                }
            }
        } else {
            for (idx, _) in relayConnections.enumerated() {
                relayConnections[idx].send(event: event)
            }
        }
    }
    
    public func add(relayUrl: String, write: Bool = false, subscriptions: [Subscription] = []) {
        let relayDef = RelayDef(relayUrl: relayUrl, write: write, subscriptions: subscriptions)
        self.add(relayDef: relayDef)
    }
    
    public func add(relayDef: RelayDefinition) {
        if !relayConnections.contains(where: { $0.relayDefinition.relayUrl == relayDef.relayUrl }) {
            if let relayConnection = RelayConnection(relayDefinition: relayDef, delegate: self) {
                relayConnection.connect()
                self.relayConnections.append(relayConnection)
            }
        }
    }
    
    public func add(subscriptions: [Subscription], onlyToRelayUrls relayUrls: [String]? = nil) {
        if let relayUrls = relayUrls {
            for url in relayUrls {
                if let indexOf = self.relayConnections.firstIndex(where: { $0.relayDefinition.relayUrl == url }) {
                    self.relayConnections[indexOf].add(subscriptions: subscriptions)
                }
            }
        } else {
            for (idx, _) in relayConnections.enumerated() {
                relayConnections[idx].add(subscriptions: subscriptions)
            }
        }
    }
    
    public func remove(with relayUrl: String) {
        let relayDef = RelayDef(relayUrl: relayUrl, write: false)
        self.remove(relayDefintion: relayDef)
    }
    
    public func remove(relayDefintion: RelayDefinition) {
        if let indexOf = self.relayConnections.firstIndex(where: { $0.relayDefinition.relayUrl == relayDefintion.relayUrl }) {
            self.relayConnections[indexOf].disconnect()
            self.relayConnections[indexOf].delegate = nil
            self.relayConnections.remove(at: indexOf)
        }
    }
    
}

public protocol NostrClientDelegate: AnyObject {
    func didReceive(message: RelayMessage, relayUrl: String)
}

extension NostrClient: RelayConnectionDelegate {
    
    public func didReceive(message: Nostr.RelayMessage, relayUrl: String) {
        delegate?.didReceive(message: message, relayUrl: relayUrl)
    }
    
}
