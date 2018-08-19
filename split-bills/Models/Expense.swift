//
//  Expense.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 7/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct Expense {

    enum SplitType: Int {
        case equallyWithAll
        case equallyCustom
        case byAmount
        case byWeight
    }

    let id: Int64
    let payer: Participant
    let description: String
    let amount: Double
    let participantsWeight: [ExpenseWeight]
    let splitType: SplitType
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

    static func equallySplited(with split: Split, payer: Participant, participants: [Participant], description: String, amount: Double, id: Int64?) -> Expense? {
        guard participants.count > 0 else {
            print("Tried to create an expense with no participants")
            return nil
        }

        let weight = 1 / Double(participants.count)
        let participantsWeight = participants.map { ExpenseWeight(participant: $0, weight: weight) }
        let splitType: Expense.SplitType = (participants.count == split.participants.count ?
            .equallyWithAll : .equallyCustom)
        return Expense(id: id ?? INTMAX_MAX, payer: payer, description: description, amount: amount, participantsWeight: participantsWeight, splitType: splitType)
    }

    typealias Amount = (Participant, Double)
    static func splitByAmount(with split: Split, payer: Participant, amounts: [Amount], description: String, amount: Double, id: Int64?) -> Expense? {
        guard amounts.count > 0 else {
            print("Tried to create an expense with no participants")
            return nil
        }

        let participantsWeight = amounts.map { ExpenseWeight(participant: $0.0, weight: $0.1 / amount) }
        return Expense(id: id ?? INTMAX_MAX, payer: payer, description: description, amount: amount, participantsWeight: participantsWeight, splitType: .byAmount)
    }

    typealias Weight = (Participant, Double)
    static func splitByWeight(with split: Split, payer: Participant, weights: [Weight], description: String, amount: Double, id: Int64?) -> Expense? {
        guard weights.count > 0 else {
            print("Tried to create an expense with no participants")
            return nil
        }

        let totalWeight = weights.map { $0.1 }.reduce(0) { return $0 + $1 }
        guard totalWeight > 0 else {
            print("Total weight must be greater than 0")
            return nil
        }

        let participantsWeight = weights.map { ExpenseWeight(participant: $0.0, weight: $0.1 / totalWeight) }
        return Expense(id: id ?? INTMAX_MAX, payer: payer, description: description, amount: amount, participantsWeight: participantsWeight, splitType: .byWeight)
    }
}

extension Payment: Equatable {

    static func == (lhs: Payment, rhs: Payment) -> Bool {
        return lhs.description == rhs.description
    }
}
