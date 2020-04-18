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

    func latestSplits() throws -> [SplitDTO] {
        try db.prepare(table).map { try split(with: $0) }
    }

    func create(eventName: String, participants: [String]) throws {
        let insert = table.insert(self.eventName <- eventName)
        let rowId = try db.run(insert)

        try participants.forEach { try participantsDatabase.add(participant: $0, splitId: rowId) }
    }

    func remove(splitId: Int64) throws {
        let row = table.filter(id == splitId)
        try participantsDatabase.remove(splitId: splitId)
        try db.run(row.delete())
    }

    func split(withId id: Int64) throws -> SplitDTO? {
        let query = table.filter(self.id == id)
        return try db.prepare(query).compactMap { try split(with: $0) }.first
    }

    func update(splitId: Int64, name: String, newParticipants: [String]) throws {
        let row = table.filter(id == splitId)
        let update = row.update(eventName <- name)

        try db.run(update)
        try newParticipants.forEach { try participantsDatabase.add(participant: $0, splitId: splitId) }
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

    init(databasePath: String) throws {
        db = try Connection("\(databasePath)/\(ParticipantDatabase.databaseName).sqlite3")
        try self.initializeDatabaseSchema()
    }

    private func initializeDatabaseSchema() throws {
        _ = try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(splitId)
            t.column(name)
        })
    }

    func add(participant: String, splitId: Int64) throws {
        let insert = table.insert(self.splitId <- splitId, name <- participant)
        _ = try db.run(insert)
    }

    func remove(splitId: Int64) throws {
        let participants = table.filter(self.splitId == splitId)
        try db.run(participants.delete())
    }

    func participants(for rowId: Int64) throws -> [ParticipantDTO] {
        let query = table.filter(splitId == rowId)
        return try db.prepare(query).compactMap { participant(with: $0) }
    }

    func participant(with name: String) throws -> ParticipantDTO? {
        let query = table.filter(self.name == name)
        return try db.prepare(query).compactMap { participant(with: $0) }.first
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
    private let expenseType = Expression<Int>("expenseType")

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
            t.column(expenseType)
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
        let insert = table.insert(self.splitId <- splitId, self.payerName <- payerName, self.description <- name, self.amount <- amount, self.expenseType <- expenseTypeIndex)
        let rowId = try db.run(insert)

        try weights.forEach { try weightsTable.create(expenseId: rowId, participant: $0.participant.name, weight: $0.weight) }
    }

    func update(
        expenseId: Int64,
        name: String,
        payerName: String,
        amount: Double,
        weights: [ExpenseWeightDTO],
        expenseTypeIndex: Int
    ) throws {
        let row = table.filter(id == expenseId)
        let update = row.update(description <- name, self.payerName <- payerName, self.amount <- amount, expenseType <- expenseTypeIndex)

        try db.run(update)
        try weightsTable.delete(for: expenseId)
        try weights.forEach { try weightsTable.create(expenseId: expenseId, participant: $0.participant.name, weight: $0.weight) }
    }

    func expense(withId id: Int64) throws -> ExpenseDTO? {
        let query = table.filter(self.id == id)
        return try db.prepare(query).compactMap { try expense(with: $0) }.first
    }

    func remove(expenseId: Int64) throws {
        let row = table.filter(id == expenseId)

        try weightsTable.delete(for: expenseId)
        try db.run(row.delete())
    }

    func getAll(splitId: Int64) throws -> [ExpenseDTO] {
        let query = table.filter(self.splitId == splitId)
        return try db.prepare(query).compactMap { try expense(with: $0) }
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
            expenseType: ExpenseTypeDTO(rawValue: row[expenseType])!) }
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

    func create(expenseId: Int64, participant: String, weight: Double) throws {
        let insert = table.insert(self.expenseId <- expenseId, participantName <- participant, self.weight <- weight)
        _ = try db.run(insert)
    }

    func delete(for expenseId: Int64) throws {
        let rows = table.filter(self.expenseId == expenseId)
        try db.run(rows.delete())
    }

    func get(expenseId: Int64) throws -> [ExpenseWeightDTO] {
        let query = table.filter(self.expenseId == expenseId)
        return try db.prepare(query).compactMap { try weight(with: $0) }
    }

    private func weight(with row: SQLite.Row) throws -> ExpenseWeightDTO? {
        let participant: ParticipantDTO? = try participantDatabase.participant(with: row[participantName])
        return participant.flatMap { ExpenseWeightDTO(participant: $0, weight: row[weight])}
    }
}
