//
//  Split.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

final class Split: Identifiable, ObservableObject {

    let id: Int64
    @Published var eventName: String
    @Published var participants: [Participant]

    init(id: Int64, eventName: String, participants: [Participant]) {
        self.id = id
        self.eventName = eventName
        self.participants = participants
    }
}

final class Participant: Codable, ObservableObject {

    var name: String
    var email: String?

    init(name: String, email: String? = nil) {
        self.name = name
        self.email = email
    }
}

extension Participant: Equatable, Hashable {

    static func == (lhs: Participant, rhs: Participant) -> Bool {
        return lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name.hashValue)
    }
}

extension Split {

    func settle(expenses: [Expense]) -> [Payment] {
        let paymentsValues = Dictionary(grouping: expenses) { $0.payer }
            .mapValues { $0.reduce(0) { return $0 + $1.amount } }

        var owingValues = [Participant: Double]()
        participants.forEach { participant in
            let totalOwing = expenses.reduce(0.0) { result, expense in
                guard let weight = expense.participantsWeight.first(where: { $0.participant == participant }) else {
                    return result
                }

                return result + weight.weight * expense.amount
            }

            owingValues[participant] = totalOwing * (-1)
        }

        let mergedValues = paymentsValues.merging(owingValues, uniquingKeysWith: +).sorted { $0.value > $1.value }
        return settle(mergedValues).filter { $0.amount > 0.01 }
    }

    private func settle(_ values: [(key: Participant, value: Double)]) -> [Payment] {
        guard values.count > 1 else {
            return []
        }

        guard let first = values.first, let last = values.last else {
            fatalError("something went wrong")
        }

        let sum = first.value + last.value
        var newValues = values.filter { $0.key != first.key && $0.key != last.key  }

        let payment = (sum < 0 ? Payment(payer: last.key, receiver: first.key, amount: abs(first.value)) :
            Payment(payer: last.key, receiver: first.key, amount: abs(last.value)))

        (sum < 0 ? newValues.append((last.key, sum)) : newValues.insert((first.key, sum), at: 0))

        return [payment] + settle(newValues)
    }
}

extension Split: Equatable {

    static func == (lhs: Split, rhs: Split) -> Bool {
        return lhs.eventName == rhs.eventName // Maybe do more checks in the future
    }
}
