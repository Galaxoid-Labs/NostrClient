//
//  Queue.swift
//
//
//  Created by Jacob Davis on 3/26/24.
//

import Foundation

public struct Queue<T>: CustomStringConvertible {
    
    private var elements: [T] = []
    public init() {}
    
    public var description: String {
        if isEmpty { return "Queue is empty ..." }
        return "---- Queue start ----\n"
        + elements.map({ "\($0)"}).joined(separator: " --> ")
        + "\n ---- Queue End ----"
    }
    
    var isEmpty: Bool {
        elements.isEmpty
    }
    
    var peak: T? {
        elements.first
    }
    
    mutating func enqueue(_ value: T) {
        elements.append(value)
    }
    
    mutating func dequeue() -> T? {
        isEmpty ? nil : elements.removeFirst()
    }
}
