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
        try! splitDatabase.create(eventName: "Test 1", participants: ["name 1"])
        let split = try! splitDatabase.getAll()[0]
        assert(split.name == "Test 1")
        assert(split.participants == [.init(name: "name 1")])

        assert(try! participantsDatabase.participants(for: split.id) == [.init(name: "name 1")])
    }

    func testCreateAndDeleteSplit() {
        try! splitDatabase.create(eventName: "Test 2", participants: ["name 1", "name 2"])
        let split = try! splitDatabase.getAll()[0]
        assert(try! participantsDatabase.participants(for: split.id) == [.init(name: "name 1"), .init(name: "name 2")])

        try! splitDatabase.remove(splitId: split.id)

        assert(try! splitDatabase.getAll() == [])
        assert(try! participantsDatabase.participants(for: split.id) == [])
    }
}

extension SplitDTO: Equatable {
    public static func == (lhs: SplitDTO, rhs: SplitDTO) -> Bool {
        return lhs.id == rhs.id
    }
}
