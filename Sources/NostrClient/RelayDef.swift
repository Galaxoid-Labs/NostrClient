//
//  RelayDef.swift
//
//
//  Created by Jacob Davis on 3/26/24.
//

import Foundation
import Nostr
import SwiftData

//@Model
public class RelayDef: RelayDefinition {
    public let relayUrl: String
    public var write: Bool
    public var subscriptions: [Subscription]
    
    public var urlRequest: URL? {
        return URL(string: relayUrl)
    }
    
    public init(relayUrl: String, write: Bool, subscriptions: [Subscription] = []) {
        self.relayUrl = relayUrl
        self.write = write
        self.subscriptions = subscriptions
    }
    
}
