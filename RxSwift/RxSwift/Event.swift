//
//  Event.swift
//  Rx
//
//  Created by Krunoslav Zaher on 2/8/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation


/// Due to current swift limitations, we have to include this Box in Result.
/// Swift cannot handle an enum with multiple associated data (A, NSError) where one is of unknown size (A)
/// This can be swiftified once the compiler is completed

/**
*   Represents event that happened
*   `Box` is there because of a bug in swift compiler
*       >> error: unimplemented IR generation feature non-fixed multi-payload enum layout
*/
public enum Event<Element>  {
    // Box is used is because swift compiler doesn't know
    // how to handle `Next(Element)` and it crashes.
    case Next(Box<Element>) // next element of a sequence
    case Error(ErrorType)   // sequence failed with error
    case Completed          // sequence terminated successfully
}

public func eventType<T>(event: Event<T>) -> String {
    switch event {
    case .Next:
        return "Next: \(event)"
    case .Completed:
        return "Completed"
    case .Error(let error):
        return "Error \(error)"
    }
}

public func == <T: Equatable>(lhs: Event<T>, rhs: Event<T>) -> Bool {
    switch (lhs, rhs) {
    case (.Completed, .Completed): return true
    case (.Error(let e1), .Error(let e2)): return e1 == e2
    case (.Next(let v1), .Next(let v2)): return v1.value == v2.value
    default: return false
    }
}

extension Event {
    public var isStopEvent: Bool {
        get {
            switch self {
            case .Next:
                return false
            case .Error: fallthrough
            case .Completed: return true
            }
        }
    }
    
    public var value: Element? {
        get {
            switch self {
            case .Next(let value):
                return value.value
            case .Error: fallthrough
            case .Completed: return nil
            }
        }
    }
}