import Foundation
import Nostr

public class NostrClient: ObservableObject {
    
    @Published private(set) public var relayConnections: [RelayConnection] = []
    
    public var delegate: NostrClientDelegate?
    
    public init() {}
    
    public func send(event: Event, onlyToRelayUrls relayUrls: [String]? = nil) {
        if let relayUrls = relayUrls {
            for url in relayUrls {
                if let indexOf = self.relayConnections.firstIndex(where: { $0.relayUrl == url }) {
                    self.relayConnections[indexOf].send(event: event)
                }
            }
        } else {
            for (idx, _) in relayConnections.enumerated() {
                relayConnections[idx].send(event: event)
            }
        }
    }
    
    public func connect(relayWithUrl relayUrl: String? = nil) {
        for relayConnection in relayConnections {
            if relayConnection.relayUrl == relayUrl || relayUrl == nil {
                relayConnection.connect()
            }
        }
    }
    
    public func add(relayWithUrl relayUrl: String, subscriptions: [Subscription] = []) {
        if !relayConnections.contains(where: { $0.relayUrl == relayUrl }) {
            if let relayConnection = RelayConnection(relayUrl: relayUrl, subscriptions: subscriptions, delegate: self) {
                relayConnection.connect()
                self.relayConnections.append(relayConnection)
            }
        }
    }
    
    public func add(subscriptions: [Subscription], onlyToRelayUrls relayUrls: [String]? = nil) {
        if let relayUrls = relayUrls {
            for url in relayUrls {
                if let indexOf = self.relayConnections.firstIndex(where: { $0.relayUrl == url }) {
                    self.relayConnections[indexOf].add(subscriptions: subscriptions)
                }
            }
        } else {
            for (idx, _) in relayConnections.enumerated() {
                relayConnections[idx].add(subscriptions: subscriptions)
            }
        }
    }
    
    public func remove(relayWithUrl relayUrl: String) {
        if let indexOf = self.relayConnections.firstIndex(where: { $0.relayUrl == relayUrl }) {
            self.relayConnections[indexOf].disconnect()
            self.relayConnections[indexOf].delegate = nil
            self.relayConnections.remove(at: indexOf)
        }
    }
    
    public static func fetchRelayInfo(relayUrl: String) async -> (url: String, info: RelayInfo)? {
        let correctedUrl = relayUrl
            .replacingOccurrences(of: "wss://", with: "https://")
            .replacingOccurrences(of: "ws://", with: "http://")
        
        guard let url = URL(string: correctedUrl) else { return nil }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/nostr+json", forHTTPHeaderField: "Accept")
        
        if let res = try? await URLSession.shared.data(for: urlRequest) {
            let decoder = JSONDecoder()
            let info = try? decoder.decode(RelayInfo.self, from: res.0)
            return (url: relayUrl, info: info) as? (url: String, info: RelayInfo)
        }
        
        return nil
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
