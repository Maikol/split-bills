//
//  SplitController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct SplitController {

    static let shared = SplitController()

    private let database: SplitDatabase?

    init() {
        do {
            database = try SplitDatabase(databasePath: URL.documentsDirectory.absoluteString)
        } catch {
            database = nil
        }
    }

    func add(split: Split) {
        do {
            try self.database?.add(split: split)
        } catch {
            print("failed to add split item")
        }
    }

    func getAll() -> [Split]? {
        do {
            return try self.database?.getAll()
        } catch {
            print("failed to get split items")
            return nil
        }
    }
}

extension URL {

    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsURL = paths.first else {
            print("Missing a documents directory")
            fatalError()
        }

        return documentsURL
    }
}
