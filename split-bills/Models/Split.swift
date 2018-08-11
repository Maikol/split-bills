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

extension Split {

    func settle(expenses: [Expense]) -> [Payment] {
        let paymentsValues = Dictionary(grouping: expenses) { expense in
            return expense.payer
            }.mapValues { $0.reduce(0) { return $0 + $1.amount } }

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

        let mergedValues = paymentsValues.merging(owingValues) { $0 + $1 }.sorted { $0.value > $1.value }
        return settle(mergedValues).filter { $0.amount > 0.01 }
    }

    private func settle(_ values: [(key: Participant, value: Double)]) -> [Payment] {
        guard values.count > 1 else {
            print("Probably something wen't wrong")
            return []
        }

        guard let first = values.first, let last = values.last else {
            fatalError("something went wrong")
        }

        let sum = first.value + last.value

        if sum < 0 {
            let paymen = Payment(payer: last.key, receiver: first.key, amount: abs(first.value))
            var newValues = values.filter { $0.key != first.key && $0.key != last.key  }
            newValues.append((last.key, last.value + first.value))
            return [paymen] + settle(newValues)
        } else {
            let paymen = Payment(payer: last.key, receiver: first.key, amount: abs(last.value))
            var newValues = values.filter { $0.key != first.key && $0.key != last.key  }
            newValues.insert((first.key, first.value + last.value), at: 0)
            return [paymen] + settle(newValues)
        }
    }
}
