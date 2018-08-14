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

extension Form {

    static func setUpDefaultStyle() {
        LabelRow.defaultCellUpdate = { cell, _ in
            cell.contentView.backgroundColor = .red
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = .boldSystemFont(ofSize: 13)
            cell.textLabel?.textAlignment = .right
        }

        TextRow.defaultCellUpdate = { _, row in
            let rowIndex = row.indexPath!.row
            while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                row.section?.remove(at: rowIndex + 1)
            }
            if !row.isValid {
                for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                    let labelRow = LabelRow() {
                        $0.title = validationMsg
                        $0.cell.height = { 30 }
                    }
                    row.section?.insert(labelRow, at: row.indexPath!.row + index + 1)
                }
            }
        }

        DecimalRow.defaultCellUpdate = { _, row in
            let rowIndex = row.indexPath!.row
            while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                row.section?.remove(at: rowIndex + 1)
            }
            if !row.isValid {
                for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                    let labelRow = LabelRow() {
                        $0.title = validationMsg
                        $0.cell.height = { 30 }
                    }
                    row.section?.insert(labelRow, at: row.indexPath!.row + index + 1)
                }
            }
        }

        PushRow<String>.defaultCellUpdate = { _, row in
            let rowIndex = row.indexPath!.row
            while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                row.section?.remove(at: rowIndex + 1)
            }
            if !row.isValid {
                for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                    let labelRow = LabelRow() {
                        $0.title = validationMsg
                        $0.cell.height = { 30 }
                    }
                    row.section?.insert(labelRow, at: row.indexPath!.row + index + 1)
                }
            }
        }

        NameRow.defaultCellUpdate = { cell, row in
            if !row.isValid {
                cell.textField.attributedPlaceholder = NSAttributedString(
                    string: cell.textField.placeholder ?? "",
                    attributes: [.foregroundColor: UIColor.red])
            } else {
                cell.textField.attributedPlaceholder = NSAttributedString(
                    string: cell.textField.placeholder ?? "")
            }
        }
    }
}
