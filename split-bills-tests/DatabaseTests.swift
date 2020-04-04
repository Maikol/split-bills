//
//  DatabaseTests.swift
//  split-bills-tests
//
//  Created by Carlos Miguel de Elias on 23/2/19.
//  Copyright © 2019 Carlos Miguel de Elias. All rights reserved.
//

import XCTest
@testable import split_bills

class DatabaseTests: XCTestCase {

    var splitDatabase: SplitDatabase!
    var participantsDatabase: ParticipantDatabase!

    override func setUp() {
        let documentsURLPath =  "\(URL.documentsDirectory.path)/tests"

        do {
            try FileManager.default.removeItem(atPath: "\(documentsURLPath)/split_database.sqlite3")
            try FileManager.default.removeItem(atPath: "\(documentsURLPath)/participant_database.sqlite3")
        } catch {
            print("could not delete existing database")
        }

        do {
            try FileManager.default.createDirectory(atPath: documentsURLPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("could not create directory")
        }
        
        splitDatabase = try! SplitDatabase(databasePath: documentsURLPath)
        participantsDatabase = try! ParticipantDatabase(databasePath: documentsURLPath)
    }

    func testCreateSplit() {
        let split = try! splitDatabase.create(eventName: "Test 1", participants: [participant1])
        assert(split.eventName == "Test 1")
        assert(split.participants == [participant1])

        assert(try! splitDatabase.getAll() == [split])
        assert(try! participantsDatabase.participants(for: split.id) == [participant1])
    }

    func testCreateAndDeleteSplit() {
        let split = try! splitDatabase.create(eventName: "Test 2", participants: [participant1, participant2])

        assert(try! splitDatabase.getAll() == [split])
        assert(try! participantsDatabase.participants(for: split.id) == [participant1, participant2])

        try! splitDatabase.remove(split: split)

        assert(try! splitDatabase.getAll() == [])
        assert(try! participantsDatabase.participants(for: split.id) == [])
    }
}
