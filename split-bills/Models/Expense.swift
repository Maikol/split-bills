//
//  Expense.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 7/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct Expense {

    let id: Int64
    let payer: Participant
    let description: String
    let amount: Double
    let participantsWeight: [ExpenseWeight]
}

struct ExpenseWeight {

    let participant: Participant
    let weight: Double
}

struct Payment {

    let payer: Participant
    let receiver: Participant
    let amount: Double

    var description: String {
        return "\(payer.name) nees to pay \(amount) to \(receiver.name)"
    }
}

extension Expense: Equatable {

    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Expense {

    static func equallySplited(with split: Split, payer: Participant, participants: [Participant], description: String, amount: Double) -> Expense? {
        guard participants.count > 0 else {
            print("Tried to create an expense with no participants")
            return nil
        }

        let weight = 1 / Double(participants.count)
        let participantsWeight = participants.map { ExpenseWeight(participant: $0, weight: weight) }
        return Expense(id: INTMAX_MAX, payer: payer, description: description, amount: amount, participantsWeight: participantsWeight)
    }

    typealias Amount = (Participant, Double)
    static func splitByAmount(with split: Split, payer: Participant, amounts: [Amount], description: String, amount: Double) -> Expense? {
        guard amounts.count > 0 else {
            print("Tried to create an expense with no participants")
            return nil
        }

        let participantsWeight = amounts.map { ExpenseWeight(participant: $0.0, weight: $0.1 / amount) }
        return Expense(id: INTMAX_MAX, payer: payer, description: description, amount: amount, participantsWeight: participantsWeight)
    }

    typealias Weight = (Participant, Double)
    static func splitByWeight(with split: Split, payer: Participant, weights: [Weight], description: String, amount: Double) -> Expense? {
        guard weights.count > 0 else {
            print("Tried to create an expense with no participants")
            return nil
        }

        let totalWeight = weights.map { $0.1 }.reduce(0) { return $0 + $1 }
        let participantsWeight = weights.map { ExpenseWeight(participant: $0.0, weight: $0.1 / totalWeight) }
        return Expense(id: INTMAX_MAX, payer: payer, description: description, amount: amount, participantsWeight: participantsWeight)
    }
}

extension Payment: Equatable {

    static func == (lhs: Payment, rhs: Payment) -> Bool {
        return lhs.description == rhs.description
    }
}
