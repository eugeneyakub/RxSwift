//
//  Observable+Multiple.swift
//  Rx
//
//  Created by Krunoslav Zaher on 3/12/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

// switch

public func switchLatest<T>
    (sources: Observable<Observable<T>>)
    -> Observable<T> {
        
    // swift doesn't have co/contravariance
    return Switch(sources: sources)
}

// combine latest

public func combineLatestOrDie<E1, E2, R>
    (with: Observable<E1>, resultSelector: (E1, E2) -> Result<R>)
    -> (Observable<E2> -> Observable<R>) {
    return { source in
        return CombineLatest(observable1: with, observable2: source, selector: resultSelector)
    }
}

public func combineLatest<E1, E2, R>
    (with: Observable<E1>, resultSelector: (E1, E2) -> R)
    -> (Observable<E2> -> Observable<R>) {
    return { source in
        return CombineLatest(observable1: with, observable2: source, selector: { success(resultSelector($0, $1)) })
    }
}

// concat

public func concat<E>
    (sources: [Observable<E>])
    -> Observable<E> {
        return Concat(sources: sources)
}

// merge

public func merge<E>
    (sources: Observable<Observable<E>>)
    -> Observable<E> {
        return Merge(sources: sources, maxConcurrent: 0)
}

public func merge<E>
    (maxConcurrent: Int)
    -> (Observable<Observable<E>> -> Observable<E>) {
    return  { sources in
        return Merge(sources: sources, maxConcurrent: maxConcurrent)
    }
}