//
//  ObserveSingleOn.swift
//  Rx
//
//  Created by Krunoslav Zaher on 3/15/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

// This class is used to forward sequence of AT MOST ONE observed element to
// another schedule.
//
// In case sequence contains more then one element, it will fire an exception.

class ObserveSingleOnObserver<ElementType> : ObserverClassType, Disposable {
    typealias Element = ElementType
    typealias Parent = ObserveSingleOn<ElementType>
    typealias State = (
        observer: ObserverOf<ElementType>,
        cancel: Disposable,
        disposed: Bool,
        element: Event<ElementType>?
    )
    
    let parent: Parent
   
    var lock = Lock()
    var state: State
    
    init(parent: Parent, observer: ObserverOf<ElementType>, cancel: Disposable) {
        self.parent = parent
        self.state = (
            observer: observer,
            cancel: cancel,
            disposed: false,
            element: nil
        )
    }
 
    func on(event: Event<Element>) -> Result<Void> {
        var elementToForward: Event<Element>?
        var stopEventToForward: Event<Element>?
        var observer: ObserverOf<Element>?
        
        self.lock.performLocked {
            let scheduler = self.parent.scheduler
            
            switch event {
            case .Next:
                if self.state.element != nil {
                    rxFatalError("Sequence contains more then one element")
                }
                
                self.state.element = event
            case .Error:
                if self.state.element != nil {
                    rxFatalError("Observed sequence was expected to have more then one element")
                }
                stopEventToForward = event
                observer = self.state.observer
            case .Completed:
                elementToForward = self.state.element
                stopEventToForward = event
                observer = self.state.observer
            }
        }
        
        if let stopEventToForward = stopEventToForward {
            self.parent.scheduler.schedule(()) { (_) in
                var r = SuccessResult
                if let elementToForward = elementToForward {
                    r = observer!.on(elementToForward)
                }
                
                r = r >>! { error in
                    observer!.on(.Error(error))
                }
                
                r = r >>> { observer!.on(stopEventToForward) }
                
                self.dispose()
                
                return r
            }
        }
        
        return SuccessResult
    }
    
    func dispose() {
        if state.disposed {
            return
        }
        
        var cancel: Disposable? = self.lock.calculateLocked {
            if self.state.disposed {
                return nil
            }
            
            var cancel = self.state.cancel
            
            self.state.disposed = true
            self.state.cancel = DefaultDisposable()
            self.state.observer = ObserverOf(NopObserver())
            
            return cancel
        }
        
        if let cancel = cancel {
            cancel.dispose()
        }
    }
    
    func run() -> Result<Disposable> {
        return self.parent.source.subscribeSafe(ObserverOf(self))
    }
}

class ObserveSingleOn<Element> : Producer<Element> {
    let scheduler: ImmediateScheduler
    let source: Observable<Element>
    
    init(source: Observable<Element>, scheduler: ImmediateScheduler) {
        self.source = source
        self.scheduler = scheduler
    }
    
    override func run(observer: ObserverOf<Element>, cancel: Disposable, setSink: (Disposable) -> Void) -> Result<Disposable> {
        let sink = ObserveSingleOnObserver(parent: self, observer: observer, cancel: cancel)
        setSink(sink)
        return sink.run()
    }
}