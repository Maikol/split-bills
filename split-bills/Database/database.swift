//
//  database.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import SQLite

struct SplitDatabase {

    private static let databaseName = "split_database"

    private let participantsDatabase: ParticipantDatabase
    private let expensesDatabase: ExpenseDatabase

    private let db: Connection
    private let table = Table("split3")

    private let id = Expression<Int64>("id")
    private let eventName = Expression<String>("event_name")

    init(databasePath: String) throws {
        participantsDatabase = try ParticipantDatabase(databasePath: databasePath)
        expensesDatabase = try ExpenseDatabase(databasePath: databasePath)
        db = try Connection("\(databasePath)/\(SplitDatabase.databaseName).sqlite3")
        try self.initializeDatabaseSchema()
    }

    private func initializeDatabaseSchema() throws {
        _ = try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(eventName, unique: true)
        })
    }

    func create(eventName: String, participants: [Participant]) throws -> Split {
        let insert = table.insert(self.eventName <- eventName)
        let rowId = try db.run(insert)

        try participants.forEach { try participantsDatabase.add(participant: $0, splitId: rowId) }

        return Split(id: rowId, eventName: eventName, participants: participants)
    }

    func remove(split: Split) throws {
        let row = table.filter(eventName == split.eventName)
        try participantsDatabase.remove(splitId: split.id)
        try db.run(row.delete())
    }

    func getAll() throws -> [Split] {
        return try db.prepare(table).compactMap { try split(with: $0) }
    }

    private func split(with row: SQLite.Row) throws -> Split? {
        let participants = try participantsDatabase.participants(for: row[id])
        let expenses = try expensesDatabase.getAll(splitName: row[eventName])
        return Split(id: row[id], eventName: row[eventName], participants: participants, expenses: expenses)
    }
}

struct ParticipantDatabase {

    private static let databaseName = "participant_database"

    private let db: Connection
    private let table = Table("participant")

    private let id = Expression<Int64>("id")
    private let splitId = Expression<Int64>("split_id")
    private let name = Expression<String>("name")
    private let email = Expression<String?>("email")

    init(databasePath: String) throws {
        db = try Connection("\(databasePath)/\(ParticipantDatabase.databaseName).sqlite3")
        try self.initializeDatabaseSchema()
    }

    private func initializeDatabaseSchema() throws {
        _ = try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(splitId)
            t.column(name)
            t.column(email)
        })
    }

    func add(participant: Participant, splitId: Int64) throws {
        let insert = table.insert(self.splitId <- splitId, name <- participant.name, email <- participant.email)
        _ = try db.run(insert)
    }

    func remove(splitId: Int64) throws {
        let participants = table.filter(self.splitId == splitId)
        try db.run(participants.delete())
    }

    func participants(for rowId: Int64) throws -> [Participant] {
        let query = table.filter(splitId == rowId)
        return try db.prepare(query).compactMap { participant(with: $0) }
    }

    func participant(with name: String) throws -> Participant? {
        let query = table.filter(self.name == name)
        return try db.prepare(query).compactMap { participant(with: $0) }.first
    }

    private func participant(with row: SQLite.Row) -> Participant? {
        return Participant(name: row[name], email: row[email])
    }
}

struct ExpenseDatabase {

    private let weightsTable: ExpsenseWeightDatabase
    private let participantDatabase: ParticipantDatabase

    private let db: Connection
    private let table = Table("expense")

    private let id = Expression<Int64>("id")
    private let splitName = Expression<String>("split_name")
    private let payerName = Expression<String>("payer_name")
    private let description = Expression<String>("description")
    private let amount = Expression<Double>("amount")
    private let splitType = Expression<Int>("splitType")

    init(databasePath: String) throws {
        weightsTable = try ExpsenseWeightDatabase(databasePath: databasePath)
        participantDatabase = try ParticipantDatabase(databasePath: databasePath)

        db = try Connection("\(databasePath)/expenses_database.sqlite3")
        try self.initializeDatabaseSchema()
    }

    private func initializeDatabaseSchema() throws {
        _ = try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(splitName)
            t.column(payerName)
            t.column(description)
            t.column(amount)
            t.column(splitType)
        })
    }

    func add(expense: Expense, splitName: String) throws -> Expense {
        let insert = table.insert(self.splitName <- splitName, payerName <- expense.payer.name, description <- expense.description, amount <- expense.amount, splitType <- expense.splitType.rawValue)
        let rowId = try db.run(insert)

        try expense.participantsWeight.forEach { try weightsTable.add(weight: $0, expenseId: rowId) }

        return Expense(
            id: rowId,
            payer: expense.payer,
            description: expense.description,
            amount: expense.amount,
            participantsWeight: expense.participantsWeight,
            splitType: expense.splitType)
    }

    func update(expense: Expense) throws {
        let row = table.filter(id == expense.id)
        let update = row.update(description <- expense.description, payerName <- expense.payer.name, amount <- expense.amount, splitType <- expense.splitType.rawValue)

        try db.run(update)
        try weightsTable.delete(for: expense.id)
        try expense.participantsWeight.forEach { try weightsTable.add(weight: $0, expenseId: expense.id) }
    }

    func remove(expense: Expense) throws {
        let row = table.filter(id == expense.id)

        try weightsTable.delete(for: expense.id)
        try db.run(row.delete())
    }

    func getAll(splitName: String) throws -> [Expense] {
        let query = table.filter(self.splitName == splitName)
        return try db.prepare(query).compactMap { try expense(with: $0) }
    }

    private func expense(with row: SQLite.Row) throws -> Expense? {
        let weights = try weightsTable.get(expenseId: row[id])
        let payer = try participantDatabase.participant(with: row[payerName])

        return payer.flatMap { Expense(id: row[id], payer: $0, description: row[description], amount: row[amount], participantsWeight: weights, splitType: Expense.SplitType(rawValue: row[splitType])!) }
    }
}

struct ExpsenseWeightDatabase {

    private let participantDatabase: ParticipantDatabase

    private let db: Connection
    private let table = Table("expense_weight")

    private let id = Expression<Int64>("id")
    private let expenseId = Expression<Int64>("expense_id")
    private let participantName = Expression<String>("participant_name")
    private let weight = Expression<Double>("weight")

    init(databasePath: String) throws {
        participantDatabase = try ParticipantDatabase(databasePath: databasePath)
        db = try Connection("\(databasePath)/expenses_weight_database.sqlite3")
        try self.initializeDatabaseSchema()
    }

    private func initializeDatabaseSchema() throws {
        _ = try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(expenseId)
            t.column(participantName)
            t.column(weight)
        })
    }

    func add(weight: ExpenseWeight, expenseId: Int64) throws {
        let insert = table.insert(self.expenseId <- expenseId, participantName <- weight.participant.name, self.weight <- weight.weight)
        _ = try db.run(insert)
    }

    func delete(for expenseId: Int64) throws {
        let rows = table.filter(self.expenseId == expenseId)
        try db.run(rows.delete())
    }

    func get(expenseId: Int64) throws -> [ExpenseWeight] {
        let query = table.filter(self.expenseId == expenseId)
        return try db.prepare(query).compactMap { try weight(with: $0) }
    }

    func weight(with row: SQLite.Row) throws -> ExpenseWeight? {
        let participant = try participantDatabase.participant(with: row[participantName])
        return participant.flatMap { ExpenseWeight(participant: $0, weight: row[weight])}
    }
}
