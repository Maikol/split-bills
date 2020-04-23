//
//  UITestingEnvironment.swift
//  split-bills
//
//  Created by Carlos DeElias on 23/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct UITestingEnvironment {

    enum ApplicationLaunchOption: String {
        case snapshots
    }

    static func setupFor(launchOption: ApplicationLaunchOption) {
        deleteDatabases()

        switch launchOption {
        case .snapshots:
            setupForSnapshots()
        }
    }

    private static func deleteDatabases() {
        // FIXME: database Name shouldn't be hardcoded
        do {
            try FileManager.default.removeItem(atPath: "\(ApplicationState.documentsPath)/split_database.sqlite3")
            try FileManager.default.removeItem(atPath: "\(ApplicationState.documentsPath)/participant_database.sqlite3")
            try FileManager.default.removeItem(atPath: "\(ApplicationState.documentsPath)/expenses_database.sqlite3")
            try FileManager.default.removeItem(atPath: "\(ApplicationState.documentsPath)/expenses_weight_database.sqlite3")
        } catch {
            print("Skipping - Couldn't find database")
        }
    }
}

// MARK: - Snapshots

private extension UITestingEnvironment {

    static func setupForSnapshots() {
        let splitDatabase = try! SplitDatabase(databasePath: ApplicationState.documentsPath)
        let expensesDatabase = try! ExpenseDatabase(databasePath: ApplicationState.documentsPath)

        let bob = ParticipantDTO(name: "Bob")
        let alice = ParticipantDTO(name: "Alice")
        let issac = ParticipantDTO(name: "Issac")
        let jenna = ParticipantDTO(name: "Jenna")

        let participants = [bob, alice, issac, jenna]

        do {
            // TODO: Localization
            // Splits
            let splitId = try splitDatabase.create(eventName: "Friday night dinner", participants: participants.map { $0.name })
            try splitDatabase.create(eventName: "Beach day", participants: participants.map { $0.name })
            try splitDatabase.create(eventName: "Scuba trip", participants: participants.map { $0.name })

            // Expenses
            try expensesDatabase.create(splitId: splitId, name: "Appetizers", payerName: "Alice", amount: 40, weights: participants.map { .init(participant: $0, weight: 0.25) }, expenseTypeIndex: 0)
            try expensesDatabase.create(splitId: splitId, name: "Starters", payerName: "Bob", amount: 60, weights: participants.map { .init(participant: $0, weight: 0.25) }, expenseTypeIndex: 0)
            try expensesDatabase.create(splitId: splitId, name: "Food", payerName: "Issac", amount: 210, weights: participants.map { .init(participant: $0, weight: 0.25) }, expenseTypeIndex: 0)
            try expensesDatabase.create(splitId: splitId, name: "Tip", payerName: "Alice", amount: 30, weights: participants.map { .init(participant: $0, weight: 0.25) }, expenseTypeIndex: 0)
            try expensesDatabase.create(splitId: splitId, name: "Pub drinks", payerName: "Bob", amount: 210, weights: participants.map { .init(participant: $0, weight: 0.25) }, expenseTypeIndex: 0)
            try expensesDatabase.create(splitId: splitId, name: "Snacks", payerName: "Bob", amount: 23, weights: participants.map { .init(participant: $0, weight: 0.25) }, expenseTypeIndex: 0)
            try expensesDatabase.create(splitId: splitId, name: "Cab", payerName: "Jenna", amount: 37.5, weights: [.init(participant: issac, weight: 0.5), .init(participant: jenna, weight: 0.5)], expenseTypeIndex: 0)
        } catch {
            fatalError("")
        }
    }
}
