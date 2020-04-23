//
//  ApplicationState.swift
//  split-bills
//
//  Created by Carlos DeElias on 22/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct ApplicationState {

    static let documentsPath: String = {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if environment["UI_TESTING"] != nil {
            try! FileManager.default.createDirectory(atPath: "\(URL.documentsDirectory.path)/UITesting", withIntermediateDirectories: true, attributes: nil)
            return "\(URL.documentsDirectory.path)/UITesting"
        } else {
            return URL.documentsDirectory.path
        }
        #else
        return URL.documentsDirectory.path
        #endif
    }()
}

extension URL {

    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsURL = paths.first else {
            fatalError("Missing a documents directory")
        }

        return documentsURL
    }
}
