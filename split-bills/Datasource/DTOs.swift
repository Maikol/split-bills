//
//  DTOs.swift
//  split-bills
//
//  Created by Carlos DeElias on 18/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct SplitDTO {
    let id: Int64
    let name: String
    let participants: [ParticipantDTO]
    let expenses: [ExpenseDTO]

    static let empty = SplitDTO(id: 0, name: "", participants: [], expenses: [])
}

struct ParticipantDTO: Equatable {
    let name: String
}

struct ExpenseDTO {
    let id: Int64
    let name: String
    let payer: ParticipantDTO
    let amount: Double
    let participantsWeight: [ExpenseWeightDTO]
    let expenseType: ExpenseTypeDTO

    static let empty = ExpenseDTO(id: 0, name: "", payer: .init(name: ""), amount: 0, participantsWeight: [], expenseType: .equallyWithAll)
}

struct ExpenseWeightDTO {
    let participant: ParticipantDTO
    let weight: Double
}

enum ExpenseTypeDTO: Int {
    case equallyWithAll
    case equallyCustom
    case byAmount
}

#if DEBUG
extension SplitDTO {
    static let example = SplitDTO(id: 0, name: "Dinner", participants: .example, expenses: [])
}

extension ExpenseDTO {
    static let example = ExpenseDTO(id: 0, name: "Wine", payer: .bob, amount: 20, participantsWeight: .example, expenseType: .equallyWithAll)
}

extension ParticipantDTO {
    static let bob = ParticipantDTO(name: "Bob")
    static let alice = ParticipantDTO(name: "Alice")
}

extension Array where Element == ParticipantDTO {
    static let example: [ParticipantDTO] = [.bob, .alice]
}

extension Array where Element == ExpenseDTO {
    static let example: [ExpenseDTO] = [.init(
        id: 0,
        name: "drinks",
        payer: .alice,
        amount: 40.0,
        participantsWeight: [.init(participant: .alice, weight: 0.5), .init(participant: .bob, weight: 0.5)],
        expenseType: .equallyWithAll)
    ]
}

extension Array where Element == ExpenseWeightDTO {
    static let example: [ExpenseWeightDTO] = [
        .init(participant: .bob, weight: 0.5),
        .init(participant: .alice, weight: 0.5)
    ]
}
#endif
