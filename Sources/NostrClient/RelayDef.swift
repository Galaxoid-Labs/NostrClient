//
//  RelayDef.swift
//
//
//  Created by Jacob Davis on 3/26/24.
//

import Foundation
import Nostr

public struct RelayDef: Codable {
    public let relayUrl: String
    public var write: Bool
    public var subscriptions: [Subscription]
    
    var urlRequest: URLRequest? {
        guard let url = URL(string: relayUrl) else { return nil }
        return URLRequest(url: url)
    }
    
    public init(relayUrl: String, write: Bool, subscriptions: [Subscription] = []) {
        self.relayUrl = relayUrl
        self.write = write
        self.subscriptions = subscriptions
    }
    
    public mutating func add(subscriptions: [Subscription]) {
        self.subscriptions.append(contentsOf: subscriptions) // TODO: Some way to check if theres a dupe? Not sure...
    }
    
}

extension RelayDef: Hashable {
    public static func == (lhs: RelayDef, rhs: RelayDef) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(relayUrl)
    }
}
