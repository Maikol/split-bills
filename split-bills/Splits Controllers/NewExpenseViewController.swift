//
//  NewExpenseViewController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 7/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import UIKit
import Eureka

protocol NewExpenseViewControllerDelegate: class {
    func didCreateNewExpense(_ expense: Expense, viewController: UIViewController)
}

final class NewExpenseViewController: FormViewController {

    enum Segment: String {
        case Equally
        case Amount
        case Weight

        static let allValues = [Equally, Amount, Weight]
    }

    weak var delegate: NewExpenseViewControllerDelegate?

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
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))

        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = doneButton
    }

    private func buildForm() {
        var totalAmount = 0.0
        var updatingFromAmount = false

        var amountTags = [String]()
        var weightTags = [String]()

        let expenseSection = Section()
            <<< TextRow() {
                $0.tag = "expense-description"
                $0.placeholder = "What was for?"
                $0.add(rule: RuleRequired())
            }
            <<< PushRow<String> {
                $0.tag = "payer-name"
                $0.title = "Payer"
                $0.add(rule: RuleRequired())
                $0.value = split.name
                $0.options = split.participants.map { $0.name }
            }
            <<< DecimalRow() {
                $0.tag = "expense-amount"
                $0.title = "Amount"
                $0.value = 0
                $0.formatter = DecimalFormatter()
                $0.useFormatterDuringInput = true
                $0.add(rule: RuleRequired())
                $0.add(rule: RuleGreaterThan(min: 1))
            }.cellSetup { cell, _  in
                cell.textField.keyboardType = .numberPad
            }.onChange { [weak self] row in
                guard let sSelf = self else { return }
                totalAmount = row.value ?? 0

                updatingFromAmount = true

                let amountRows = amountTags.compactMap { sSelf.form.rowBy(tag: $0) as? CustomDecimalRow }.filter { !$0.updated }

                if amountRows.count > 0 {
                    amountRows.forEach {
                        $0.value = totalAmount / Double(amountRows.count)
                        $0.updateCell()
                    }
                }

                updatingFromAmount = false
            }

        let splitTypeSection = Section("Split:")
            <<< SwitchRow("split-equally-switch") {
                $0.title = "Split equally between everyone"
                $0.value = true
            }

        let participantsSectionHidden = Condition.function(["split-equally-switch"]) { form in
            let row: RowOf<Bool>! = form.rowBy(tag: "split-equally-switch")
            return row.value ?? false
        }

        let weightSection = Section("Split differently") {
                $0.hidden = participantsSectionHidden
            }
            <<< SegmentedRow<Segment>("weight-segments") {
                $0.options = Segment.allValues
                $0.value = Segment.Equally
            }

        let splitEquallyHidden = Condition.function(["split-equally-switch", "weight-segments"]) { form in
            let splitEquallyRow: RowOf<Bool>! = form.rowBy(tag: "split-equally-switch")
            let weightSegmentsRow: RowOf<Segment>! = form.rowBy(tag: "weight-segments")
            return splitEquallyRow.value.flatMap { $0 || weightSegmentsRow.value != .Equally } ?? true
        }

        let splitAmountHidden = Condition.function(["split-equally-switch", "weight-segments"]) { form in
            let splitEquallyRow: RowOf<Bool>! = form.rowBy(tag: "split-equally-switch")
            let weightSegmentsRow: RowOf<Segment>! = form.rowBy(tag: "weight-segments")
            return splitEquallyRow.value.flatMap { $0 || weightSegmentsRow.value != .Amount } ?? true
        }

        let splitWeightHidden = Condition.function(["split-equally-switch", "weight-segments"]) { form in
            let splitEquallyRow: RowOf<Bool>! = form.rowBy(tag: "split-equally-switch")
            let weightSegmentsRow: RowOf<Segment>! = form.rowBy(tag: "weight-segments")
            return splitEquallyRow.value.flatMap { $0 || weightSegmentsRow.value != .Weight } ?? true
        }

        let amountUpdate: (CustomDecimalRow) -> Void = { [weak self] row in
            guard let sSelf = self, let title = row.title, let value = row.value, !updatingFromAmount else { return }

            row.updated = true

            let rows = amountTags.filter { $0 != "amount-\(title)" }.compactMap { sSelf.form.rowBy(tag: $0) as? CustomDecimalRow }.filter { !$0.updated }

            updatingFromAmount = true

            if rows.count > 0 {
                rows.forEach {
                    $0.value = (totalAmount - value) / Double(rows.count)
                    $0.updateCell()
                }
            }

            updatingFromAmount = false
        }

        let participantsSection = Section("Participants") {
                $0.hidden = participantsSectionHidden
            }

        split.participants.forEach { participant in
            participantsSection
                <<< CheckRow() {
                    $0.tag = "equally-\(participant.name)"
                    $0.title = participant.name
                    $0.value = true
                    $0.hidden = splitEquallyHidden
                }
                <<< CustomDecimalRow() {
                    let tag = "amount-\(participant.name)"
                    $0.tag = tag
                    $0.title = participant.name
                    $0.value = 0
                    $0.formatter = DecimalFormatter()
                    $0.useFormatterDuringInput = true
                    $0.hidden = splitAmountHidden
                    amountTags.append(tag)
                }.onChange(amountUpdate)
                <<< CustomDecimalRow() {
                    let tag = "weight-\(participant.name)"
                    $0.tag = tag
                    $0.title = participant.name
                    $0.value = 0
                    $0.formatter = DecimalFormatter()
                    $0.useFormatterDuringInput = true
                    $0.hidden = splitWeightHidden
                    weightTags.append(tag)
                }
        }

        form += [expenseSection, splitTypeSection, weightSection, participantsSection]
    }

    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func doneButtonTapped() {
        guard form.validate().isEmpty else { return }

        guard let payer = form.stringRow(with: "payer-name")?.value.map({ Participant(name: $0, email: nil) }),
            let description = form.stringRow(with: "expense-description")?.value,
            let amount = form.doubleRow(with: "expense-amount")?.value else { return }

        guard !form.uBoolRow(with: "split-equally-switch").value! else {
            saveEqually(payer: payer, description: description, amount: amount)
            return
        }

        guard let segmentsRow = form.rowBy(tag: "weight-segments") as? SegmentedRow<Segment>,
            let segment = segmentsRow.value else { return }

        switch segment {
        case .Equally: saveEquallySegment(payer: payer, description: description, amount: amount)
        case .Amount: saveAmountSegment(payer: payer, description: description, amount: amount)
        case .Weight: saveWeightSegment(payer: payer, description: description, amount: amount)
        }
    }

    private func saveEqually(payer: Participant, description: String, amount: Double) {
        guard split.participants.count > 0 else { return }

        let weight = 1 / Double(split.participants.count)
        let participantsWeight = split.participants.map { ExpenseWeight(participant: $0, weight: weight) }
        let expense = Expense(id: INTMAX_MAX, payer: payer, description: description, amount: amount, participantsWeight: participantsWeight)

        self.delegate?.didCreateNewExpense(expense, viewController: self)
    }

    private func saveEquallySegment(payer: Participant, description: String, amount: Double) {
        let participants = split.participants.filter { (form.rowBy(tag: "equally-\($0.name)") as? CheckRow)?.value == true }

        guard participants.count > 0 else { return }

        let weight = 1 / Double(participants.count)
        let participantsWeight = participants.map { ExpenseWeight(participant: $0, weight: weight) }
        let expense = Expense(id: INTMAX_MAX, payer: payer, description: description, amount: amount, participantsWeight: participantsWeight)

        self.delegate?.didCreateNewExpense(expense, viewController: self)
    }

    private func saveAmountSegment(payer: Participant, description: String, amount: Double) {
        let values = split.participants.compactMap { ($0, form.doubleRow(with: "amount-\($0.name)")?.value ?? 0) }

        let participantsWeight = values.map { ExpenseWeight(participant: $0.0, weight: $0.1 / amount) }
        let expense = Expense(id: INTMAX_MAX, payer: payer, description: description, amount: amount, participantsWeight: participantsWeight)

        self.delegate?.didCreateNewExpense(expense, viewController: self)
    }

    private func saveWeightSegment(payer: Participant, description: String, amount: Double) {
        let values = split.participants.compactMap { ($0, form.doubleRow(with: "weight-\($0.name)")?.value ?? 0) }

        let totalWeight = values.map { $0.1 }.reduce(0) { return $0 + $1 }
        let participantsWeight = values.map { ExpenseWeight(participant: $0.0, weight: $0.1 / totalWeight) }
        let expense = Expense(id: INTMAX_MAX, payer: payer, description: description, amount: amount, participantsWeight: participantsWeight)

        self.delegate?.didCreateNewExpense(expense, viewController: self)
    }
}

final class CustomDecimalRow: _DecimalRow, RowType {

    var updated = false
}
