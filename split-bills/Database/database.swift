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

    private let participantsDatabase: ParticipantDatabase

    private let db: Connection
    private let table = Table("split")

    private let id = Expression<Int64>("id")
    private let eventName = Expression<String>("event_name")
    private let name = Expression<String>("name")
    private let email = Expression<String?>("email")

    init(databasePath: String) throws {
        participantsDatabase = try ParticipantDatabase(databasePath: databasePath)
        db = try Connection("\(databasePath)/split_database.sqlite3")
        try self.initializeDatabaseSchema()
    }

    private func initializeDatabaseSchema() throws {
        _ = try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(eventName, unique: true)
            t.column(name)
            t.column(email)
        })
    }

    func add(split: Split) throws {
        let insert = table.insert(eventName <- split.eventName, name <- split.name, email <- split.email)
        let rowId = try db.run(insert)

        try split.participants.forEach { try participantsDatabase.add(participant: $0, splitId: rowId) }
    }

    func getAll() throws -> [Split] {
        return try db.prepare(table).compactMap { try split(with: $0) }
    }

    private func split(with row: SQLite.Row) throws -> Split? {
        let participants = try participantsDatabase.participants(for: row[id])
        return Split(eventName: row[eventName], name: row[name], email: row[email], participants: participants)
    }
}

struct ParticipantDatabase {

    private let db: Connection
    private let table = Table("participant")

    private let id = Expression<Int64>("id")
    private let splitId = Expression<Int64>("split_id")
    private let name = Expression<String>("name")
    private let email = Expression<String?>("email")

    init(databasePath: String) throws {
        db = try Connection("\(databasePath)/participant_database.sqlite3")
        try self.initializeDatabaseSchema()
    }

    private func initializeDatabaseSchema() throws {
        _ = try db.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(splitId, unique: true)
            t.column(name)
            t.column(email)
        })
    }

    func add(participant: Participant, splitId: Int64) throws {
        let insert = table.insert(self.splitId <- splitId, name <- participant.name, email <- participant.email)
        _ = try db.run(insert)
    }

    func participants(for rowId: Int64) throws -> [Participant] {
        let query = table.filter(splitId == Int64(rowId))
        return try db.prepare(query).compactMap { participant(with: $0) }
    }

    private func participant(with row: SQLite.Row) -> Participant? {
        return Participant(name: row[name], email: row[email])
    }
}
