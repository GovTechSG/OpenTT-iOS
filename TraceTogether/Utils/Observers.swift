//
//  Observers.swift
//  OpenTraceTogether

import Foundation

class Observers {
    private struct Observer {
        weak var weakRef: AnyObject?
        var callback: () -> Void
    }

    private var observers = [Observer]()

    func notify() {
        observers = observers.filter { $0.weakRef != nil }
        observers.forEach { $0.callback() }
    }

    func add(_ weakRef: AnyObject, _ callback: @escaping () -> Void) {
        observers.append(.init(weakRef: weakRef, callback: callback))
    }

    func remove(_ weakRef: AnyObject) {
        observers.removeAll { $0.weakRef === weakRef }
    }
}

class Observable<T>: Observers {

    var value: T { didSet { notify() } }

    init(_ value: T) {
        self.value = value
    }
}
