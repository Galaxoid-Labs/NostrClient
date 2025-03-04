import Foundation
import Nostr

public class NostrClient: ObservableObject {
    
    @Published private(set) public var relayConnections: [RelayConnection] = []
    
    public var delegate: NostrClientDelegate?
    
    public init() {}
   
    // allow to pass a closer for errors?
    
    public func send(event: Event, onlyToRelayUrls relayUrls: [String]? = nil, completion: ((Error?) -> Void)? = nil) {
        if let relayUrls = relayUrls {
            for url in relayUrls {
                if let indexOf = self.relayConnections.firstIndex(where: { $0.relayUrl == url }) {
                    self.relayConnections[indexOf].send(event: event, completion: completion)
                }
            }
        } else {
            for (idx, _) in relayConnections.enumerated() {
                relayConnections[idx].send(event: event, completion: completion)
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
    
    public func disconnect(relayWithUrl relayUrl: String? = nil) {
        for relayConnection in relayConnections {
            if relayConnection.relayUrl == relayUrl || relayUrl == nil {
                relayConnection.disconnect()
            }
        }
    }
    
    // This will add new relay connection if not already available
    // If the relay connection is already present it will then simply update the subscriptions
    // if they are different than whats already subscribed
    // It's worth noting if you do not specify a specific subscription id that it the subscription
    // will always be different and you could endup with subs that are very similar
    public func add(relayWithUrl relayUrl: String, subscriptions: [Subscription] = [], autoConnect: Bool = true) {
        if !relayConnections.contains(where: { $0.relayUrl == relayUrl }) {
            if let relayConnection = RelayConnection(relayUrl: relayUrl, subscriptions: subscriptions, delegate: self) {
                self.relayConnections.append(relayConnection)
                if autoConnect {
                    relayConnection.connect()
                }
            }
        } else if let indexOf = self.relayConnections.firstIndex(where: { $0.relayUrl == relayUrl }) {
            self.relayConnections[indexOf].add(subscriptions: subscriptions)
        }
    }
    
    // This will add subscriptions to found relays and also setup new relay connections if you dont already have them.
    // Same as above if the subs are different it will resubscribe any with the same id but are different
    public func add(subscriptions: [Subscription], onlyToRelayUrls relayUrls: [String]? = nil, autoConnect: Bool = true) {
        if let relayUrls = relayUrls {
            var relayUrlsNotFound: [String] = []
            for url in relayUrls {
                if let indexOf = self.relayConnections.firstIndex(where: { $0.relayUrl == url }) {
                    self.relayConnections[indexOf].add(subscriptions: subscriptions)
                } else {
                    relayUrlsNotFound.append(url)
                }
            }
            for url in relayUrlsNotFound {
                if let relayConnection = RelayConnection(relayUrl: url, subscriptions: subscriptions, delegate: self) {
                    self.relayConnections.append(relayConnection)
                    if autoConnect {
                        relayConnection.connect()
                    }
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
    func didConnect(relayUrl: String)
    func didDisconnect(relayUrl: String)
}

extension NostrClient: RelayConnectionDelegate {
    public func didConnect(relayUrl: String) {
        delegate?.didConnect(relayUrl: relayUrl)
    }
    
    public func didDisconnect(relayUrl: String) {
        delegate?.didDisconnect(relayUrl: relayUrl)
    }
    
    public func didReceive(message: Nostr.RelayMessage, relayUrl: String) {
        delegate?.didReceive(message: message, relayUrl: relayUrl)
    }
}
