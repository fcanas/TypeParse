//
//  Parse.swift
//  WhichSide
//
//  Created by Fabian Canas on 7/9/15.
//  Copyright (c) 2015 Fabián Cañas. All rights reserved.
//

import Foundation
import Parse

/// Parse Model Methods

protocol Model {
    static func className() -> String // TODO: Make this a property with Swift 2.0?
    init?(model :PFObject)

    func apply(obj :PFObject)
}

enum Constraint {
    case Ascending(String)
    case Descending(String)
    case Exists(String)
    case DoesNotExist(String)
    case HasPrefix(key: String, prefix: String)
    case LessThan(key: String, value: Double)
    case Limit(Int)
  }

extension Constraint :Equatable {}

func == (lhs: Constraint, rhs: Constraint) -> Bool {
    switch (lhs) {
    case .Ascending(let lKey):
        switch (rhs) {
        case .Ascending(let rKey) where lKey == rKey:
            return true
        default:
            return false
        }
    case .Descending(let lKey):
        switch (rhs) {
        case .Descending(let rKey) where lKey == rKey:
            return true
        default:
            return false
        }
    case .Exists(let lKey):
        switch (rhs) {
        case .Exists(let rKey) where lKey == rKey:
            return true
        default:
            return false
        }
    case .DoesNotExist(let lKey):
        switch (rhs) {
        case .DoesNotExist(let rKey) where lKey == rKey:
            return true
        default:
            return false
        }
    case .HasPrefix(key: let lKey, prefix: let lPrefix):
        switch (rhs) {
        case .HasPrefix(key: let rKey, prefix: let rPrefix) where lKey == rKey && lPrefix == rPrefix:
            return true
        default:
            return false
        }
    case .Limit(let lLimit):
        switch (rhs) {
        case .Limit(let rLimit):
            return true
        default:
            return false
        }
    }
}

struct Query<T :Model> {
    let constraints :[Constraint]

    init() {
        constraints = []
    }

    init(constraints: [Constraint]) {
        self.constraints = constraints
    }

    func ascending(key: String) -> Query<T> {
        constraints + [Constraint.Ascending(key)]
        return self
    }

    func descending(key: String) -> Query<T> {
        return Query<T>(constraints: constraints + [Constraint.Descending(key)])
    }

    func findInBackground(callback: ([T]) -> Void) {
        let q = PFQuery(className: T.className())

        map(constraints) { (constraint: Constraint) -> Void in
            switch (constraint) {
            case .Ascending(let key):
                q.addAscendingOrder(key)
                break
            case .Descending(let key):
                q.addDescendingOrder(key)
                break
            case .Exists(let key):
                q.whereKeyExists(key)
                break
            case .DoesNotExist(let key):
                q.whereKeyDoesNotExist(key)
                break
            case .HasPrefix(key: let key, prefix: let prefix):
                q.whereKey(key, hasPrefix: prefix)
                break
            case .Limit(let limit):
                q.limit = limit
            }
        }

        q.findObjectsInBackgroundWithBlock { (results, error) -> Void in
            if let results = results {
                callback(reduce(results, Array<T>()) { (var e, obj) in
                    if let pObj = obj as? PFObject, t = T(model: pObj) {
                        return e + [t]
                    }
                    return e
                    })
            }
        }
    }
}

extension Query :Equatable {}

func == <T>(lhs: Query<T>, rhs: Query<T>) -> Bool {
    return lhs.constraints == rhs.constraints
}

func save<T: Model>(model :T) {
    let obj = PFObject(className: T.className())
    model.apply(obj)
    obj.saveInBackgroundWithBlock(nil)
}
