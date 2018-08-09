//
//  Split.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct Split {

    let eventName: String
    let name: String
    let email: String?
    let participants: [Participant]
}

struct Participant {

    let name: String
    let email: String?
}

extension Participant: Equatable, Hashable {

    static func == (lhs: Participant, rhs: Participant) -> Bool {
        return lhs.name == rhs.name
    }

    var hashValue: Int {
        return name.hashValue
    }
}
