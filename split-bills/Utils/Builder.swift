//
//  Builder.swift
//  split-bills
//
//  Created by Carlos DeElias on 15/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

protocol Builder {}

extension Builder {
    func set<T>(_ keyPath: WritableKeyPath<Self, T>, to newValue: T) -> Self {
        var copy = self
        copy[keyPath: keyPath] = newValue
        return copy
    }
}
