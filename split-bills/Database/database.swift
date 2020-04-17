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
    private let table = Table("split")

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

    func latestSplits() throws -> [SplitDTO] {
        try db.prepare(table).map { try split(with: $0) }
    }

    func split(withId id: Int64) throws -> SplitDTO? {
        let query = table.filter(self.id == id)
        return try db.prepare(query).compactMap { try split(with: $0) }.first
    }

    @available(*, deprecated, renamed: "update(splitId:name:newParticipants:)")
    func update(split: Split) throws {
        let row = table.filter(id == split.id)
        let update = row.update(eventName <- split.eventName)

        try db.run(update)
        let oldParticipants: [Participant] = try participantsDatabase.participants(for: split.id)
        let newParticipants = split.participants.difference(from: oldParticipants)

        try newParticipants.forEach { try participantsDatabase.add(participant: $0, splitId: split.id) }
    }

    func update(splitId: Int64, name: String, newParticipants: [ParticipantDTO]) throws {
        let row = table.filter(id == splitId)
        let update = row.update(eventName <- name)

        try db.run(update)
        try newParticipants.forEach { try participantsDatabase.add(participant: Participant(name: $0.name), splitId: splitId) }
    }

    private func split(with row: SQLite.Row) throws -> SplitDTO {
        let participants: [ParticipantDTO] = try participantsDatabase.participants(for: row[id])
        let expenses: [ExpenseDTO] = try expensesDatabase.getAll(splitId: row[id])
        return SplitDTO(id: row[id], name: row[eventName], participants: participants, expenses: expenses)
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

    @available(*, deprecated, message: "use return type of ParticipantDTO")
    func participants(for rowId: Int64) throws -> [Participant] {
        let query = table.filter(splitId == rowId)
        return try db.prepare(query).compactMap { participant(with: $0) }
    }

    func participants(for rowId: Int64) throws -> [ParticipantDTO] {
        let query = table.filter(splitId == rowId)
        return try db.prepare(query).compactMap { participant(with: $0) }
    }

    @available(*, deprecated, message: "use return type of ParticipantDTO")
    func participant(with name: String) throws -> Participant? {
        let query = table.filter(self.name == name)
        return try db.prepare(query).compactMap { participant(with: $0) }.first
    }

    func participant(with name: String) throws -> ParticipantDTO? {
        let query = table.filter(self.name == name)
        return try db.prepare(query).compactMap { participant(with: $0) }.first
    }

    @available(*, deprecated, message: "use return type of ParticipantDTO")
    private func participant(with row: SQLite.Row) -> Participant? {
        return Participant(name: row[name], email: row[email])
    }

    private func participant(with row: SQLite.Row) -> ParticipantDTO? {
        return ParticipantDTO(name: row[name])
    }
}

struct ExpenseDatabase {

    private let weightsTable: ExpsenseWeightDatabase
    private let participantDatabase: ParticipantDatabase

    private let db: Connection
    private let table = Table("expense")

    private let splitId = Expression<Int64>("split_id")

    private let id = Expression<Int64>("id")
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
            t.column(splitId)
            t.column(payerName)
            t.column(description)
            t.column(amount)
            t.column(splitType)
        })
    }

    func create(
        splitId: Int64,
        name: String,
        payerName: String,
        amount: Double,
        weights: [ExpenseWeightDTO],
        expenseTypeIndex: Int
    ) throws {
        let insert = table.insert(self.splitId <- splitId, self.payerName <- payerName, self.description <- name, self.amount <- amount, self.splitType <- expenseTypeIndex)
        let rowId = try db.run(insert)

        try weights.forEach { try weightsTable.create(expenseId: rowId, weight: $0) }
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

    func getAll(splitId: Int64) throws -> [ExpenseDTO] {
        let query = table.filter(self.splitId == splitId)
        return try db.prepare(query).compactMap { try expense(with: $0) }
    }

    @available(*, deprecated, message: "use ExpenseDTO")
    private func expense(with row: SQLite.Row) throws -> Expense? {
        let weights: [ExpenseWeight] = try weightsTable.get(expenseId: row[id])
        let payer: Participant? = try participantDatabase.participant(with: row[payerName])

        return payer.flatMap { Expense(id: row[id], payer: $0, description: row[description], amount: row[amount], participantsWeight: weights, splitType: Expense.SplitType(rawValue: row[splitType])!) }
    }

    private func expense(with row: SQLite.Row) throws -> ExpenseDTO? {
        let weights: [ExpenseWeightDTO] = try weightsTable.get(expenseId: row[id])
        let payer: ParticipantDTO? = try participantDatabase.participant(with: row[payerName])

        return payer.flatMap { ExpenseDTO(
            id: row[id],
            name: row[description],
            payer: $0,
            amount: row[amount],
            participantsWeight: weights,
            expenseType: ExpenseTypeDTO(rawValue: row[splitType])!) }
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

    @available(*, deprecated, renamed: "create(expenseId:weight:)")
    func add(weight: ExpenseWeight, expenseId: Int64) throws {
        let insert = table.insert(self.expenseId <- expenseId, participantName <- weight.participant.name, self.weight <- weight.weight)
        _ = try db.run(insert)
    }

    func create(expenseId: Int64, weight: ExpenseWeightDTO) throws {
        let insert = table.insert(self.expenseId <- expenseId, participantName <- weight.participant.name, self.weight <- weight.weight)
        _ = try db.run(insert)
    }

    func delete(for expenseId: Int64) throws {
        let rows = table.filter(self.expenseId == expenseId)
        try db.run(rows.delete())
    }

    @available(*, deprecated, message: "Use ExpenseWeightDTO")
    func get(expenseId: Int64) throws -> [ExpenseWeight] {
        let query = table.filter(self.expenseId == expenseId)
        return try db.prepare(query).compactMap { try weight(with: $0) }
    }

    func get(expenseId: Int64) throws -> [ExpenseWeightDTO] {
        let query = table.filter(self.expenseId == expenseId)
        return try db.prepare(query).compactMap { try weight(with: $0) }
    }

    @available(*, deprecated, message: "use ExpenseWeightDTo")
    func weight(with row: SQLite.Row) throws -> ExpenseWeight? {
        let participant: Participant? = try participantDatabase.participant(with: row[participantName])
        return participant.flatMap { ExpenseWeight(participant: $0, weight: row[weight])}
    }

    func weight(with row: SQLite.Row) throws -> ExpenseWeightDTO? {
        let participant: ParticipantDTO? = try participantDatabase.participant(with: row[participantName])
        return participant.flatMap { ExpenseWeightDTO(participant: $0, weight: row[weight])}
    }
}
