//
//  NewExpenseViewController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 7/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import UIKit
import Eureka

final class NewExpenseViewController: FormViewController {

    private let split: Split

    init(split: Split) {
        self.split = split

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        buildView()
        buildForm()
    }

    private func buildView() {
        title = "New expense"

        let closeButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))

        navigationItem.leftBarButtonItem = closeButton
    }

    private func buildForm() {
        let expenseSection = Section()
            <<< TextRow() {
                $0.tag = "expense-description"
                $0.placeholder = "What was for?"
                $0.add(rule: RuleRequired())
            }
            <<< PushRow<String> {
                $0.tag = "name"
                $0.title = "Payer"
                $0.add(rule: RuleRequired())
                $0.value = split.name
                $0.options = [split.name] + split.participants.map { $0.name }
            }
            <<< DecimalRow() {
                $0.title = "Amount"
                $0.value = 0
                $0.formatter = DecimalFormatter()
                $0.useFormatterDuringInput = true
            }.cellSetup { cell, _  in
                cell.textField.keyboardType = .numberPad
            }

        let splitTypeSection = Section("Split:")
            <<< SwitchRow("split-equally") {
                $0.title = "Split equally between everyone"
                $0.value = true
            }

        let weightSection = Section("Split differently") {
                $0.hidden = .function(["split-equally"]) { form in
                    let row: RowOf<Bool>! = form.rowBy(tag: "split-equally")
                    return row.value ?? false
                }
            }
            <<< SegmentedRow<String>("weight-segments") {
                $0.options = ["Equally", "Amount", "Weight"]
                $0.value = "Equally"
            }

        let participantsSection = Section("Participants") {
                $0.hidden = .function(["split-equally", "weight-segments"]) { form in
                    let splitEquallyRow: RowOf<Bool>! = form.rowBy(tag: "split-equally")
                    let weightSegmentsRow: RowOf<String>? = form.rowBy(tag: "weight-segments")
                    let equallySelected = (weightSegmentsRow?.value == "Equally")
                    return splitEquallyRow.value.flatMap { $0 || !equallySelected } ?? true
                }
            }
            <<< CheckRow() {
                $0.title = split.name
                $0.value = true
            }

        split.participants.forEach { participant in
            participantsSection
                <<< CheckRow() {
                    $0.title = participant.name
                    $0.value = true
                }
        }

        form += [expenseSection, splitTypeSection, weightSection, participantsSection]
    }

    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}
