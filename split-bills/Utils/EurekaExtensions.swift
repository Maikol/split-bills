//
//  EurekaExtensions.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 9/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import Eureka

extension Form {

    func stringRow(with tag: String) -> RowOf<String>? {
        return rowBy(tag: tag) as? RowOf<String>
    }

    func doubleRow(with tag: String) -> RowOf<Double>? {
        return rowBy(tag: tag) as? RowOf<Double>
    }

    func uBoolRow(with tag: String) -> RowOf<Bool> {
        return rowBy(tag: tag) as! RowOf<Bool>
    }
}
