import Foundation
import Nostr
import Starscream

public class NostrClient: ObservableObject {
    
    public init() {}

    @Published private(set) public var relayConnections: [RelayConnection] = []
    public var delegate: NostrClientDelegate?
    
    public func add(relayUrl: String, write: Bool = false, subscriptions: [Subscription] = []) {
        let relayDef = RelayDef(relayUrl: relayUrl, write: write, subscriptions: subscriptions)
        self.add(relayDef: relayDef)
    }
    
    public func add(relayDef: RelayDef) {
        if !relayConnections.contains(where: { $0.relayDef == relayDef }) {
            if let relayConnection = RelayConnection(relayDef: relayDef, delegate: self) {
                relayConnection.connect()
                self.relayConnections.append(relayConnection)
            }
        }
    }
    
    public func add(subscriptions: [Subscription], onlyToRelayUrls relayUrls: [String]? = nil) {
        if let relayUrls = relayUrls {
            for url in relayUrls {
                if let indexOf = self.relayConnections.firstIndex(where: { $0.relayDef.relayUrl == url }) {
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
        self.remove(relayDef: relayDef)
    }
    
    public func remove(relayDef: RelayDef) {
        if let indexOf = self.relayConnections.firstIndex(where: { $0.relayDef == relayDef }) {
            self.relayConnections[indexOf].disconnect()
            self.relayConnections[indexOf].delegate = nil
            self.relayConnections.remove(at: indexOf)
        }
    }
    
    public func getCurrentRelayDefs() -> [RelayDef] {
        return self.relayConnections.map({ $0.relayDef })
    }

}

public protocol NostrClientDelegate: AnyObject {
    func didReceive(message: RelayMessage, relayUrl: String)
}

extension NostrClient: RelayConnectionDelegate {
    
    public func didReceive(message: Nostr.RelayMessage, relayUrl: String) {
        //print("Received message from \(relayUrl)\n")
        delegate?.didReceive(message: message, relayUrl: relayUrl)
//        switch message {
//            case .event(let id, let event):
//                if event.isValid() {
//                    print("Valid event: \(event.id)\n")
//                    print("EventKind: \(event.kind)")
//                } else {
//                    print("Invalid event: \(event.id)")
//                }
//            case .notice(let notice):
//                print(notice)
//            case .other(let other):
//                print(other)
//        }
    }
    
}
