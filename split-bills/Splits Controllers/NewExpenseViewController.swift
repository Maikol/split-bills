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
    func didRequestSaveExpenseAndDismiss(_ expense: Expense, from viewController: UIViewController)
    func didRequestSaveAndCreateNewExpense(_ expense: Expense, from viewController: UIViewController)
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
    private let expense: Expense?

    init(split: Split, expense: Expense? = nil) {
        self.split = split
        self.expense = expense

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never

        buildView()
        buildForm()
    }

    private func buildView() {
        title = "Expense"

        tableView.backgroundColor = Color.light.value
    }

    private func buildForm() {
        var totalAmount = expense?.amount ?? 0.0
        var updatingFromAmount = false

        var amountTags = [String]()
        var weightTags = [String]()

        let expenseSection = Section {
            var header = HeaderLabel.defaultHeader
            header.onSetupView = { view, _ in
                view.update(title: "Info")
            }
            $0.header = header
        }
            <<< TextRow() {
                $0.tag = "expense-description"
                $0.value = expense?.description
                $0.add(rule: RuleRequired())
                $0.cellUpdate { cell, _ in
                    cell.textField.apply(style: .body(.dark), placeholder: .init(text: "What was for?", style: .body(.fade)))
                    cell.titleLabel?.apply(style: .body(.dark))
                }
            }
            <<< PushRow<String> {
                $0.tag = "payer-name"
                $0.title = "Payer"
                $0.add(rule: RuleRequired())
                $0.value = expense?.payer.name ?? split.participants.first?.name
                $0.options = split.participants.map { $0.name }
                $0.cellUpdate { cell, _ in
                    cell.textLabel?.apply(style: .body(.darkBold))
                    cell.detailTextLabel?.apply(style: .body(.dark))
                }
                _ = $0.onPresent { form, viewController in
                    viewController.selectableRowCellSetup = { cell, _ in
                        cell.textLabel?.apply(style: .body(.dark))
                    }
                }
            }
            <<< DecimalRow() {
                $0.tag = "expense-amount"
                $0.title = "Amount"
                $0.value = expense?.amount
                $0.useFormatterDuringInput = false
                $0.add(rule: RuleRequired())
                $0.add(rule: RuleGreaterThan(min: 1))
                $0.cellUpdate { cell, _ in
                    cell.textField.apply(style: .body(.dark))
                    cell.titleLabel?.apply(style: .body(.dark))
                }
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

        let splitTypeSection = Section  {
            var header = HeaderLabel.defaultHeader
            header.onSetupView = { view, _ in
                view.update(title: "Split")
            }
            $0.header = header
        }
            <<< SwitchRow("split-equally-switch") {
                $0.title = "Equally between everyone"
                $0.value = (expense.map { $0.splitType == .equallyWithAll } ?? true)
                $0.cellUpdate { cell, _ in
                    cell.textLabel?.apply(style: .body(.dark))
                }
            }

        let participantsSectionHidden = Condition.function(["split-equally-switch"]) { form in
            let row: RowOf<Bool>! = form.rowBy(tag: "split-equally-switch")
            return row.value ?? false
        }

        let weightSection = Section {
            $0.hidden = participantsSectionHidden
            var header = HeaderLabel.defaultHeader
            header.onSetupView = { view, _ in
                view.update(title: "Split differently")
            }
            $0.header = header
        }
            <<< SegmentedRow<Segment>("weight-segments") {
                $0.options = Segment.allValues
                $0.value = expense.flatMap { Segment(splitType: $0.splitType) } ?? Segment.Equally
                $0.cellUpdate { cell, _ in
                    cell.segmentedControl.setTitleTextAttributes(
                        [.font: Text.body(.dark).font], for: .selected)
                    cell.segmentedControl.setTitleTextAttributes(
                        [.font: Text.body(.dark).font], for: .normal)
                }
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

            let rows = amountTags.filter { $0 != "amount-\(title)" }
                .compactMap { sSelf.form.rowBy(tag: $0) as? CustomDecimalRow }
                .filter { !$0.updated }

            updatingFromAmount = true

            if rows.count > 0 {
                rows.forEach {
                    $0.value = (totalAmount - value) / Double(rows.count)
                    $0.updateCell()
                }
            }

            updatingFromAmount = false
        }

        let participantsSection = Section {
            $0.hidden = participantsSectionHidden
            var header = HeaderLabel.defaultHeader
            header.onSetupView = { view, _ in
                view.update(title: "Participants")
            }
            $0.header = header
        }

        let totalWeight = expense.map { $0.participantsWeight.reduce(0) { $0 + $1.weight } } ?? 0
        split.participants.forEach { participant in
            let equallyValue = expense.map { $0.participantsWeight.contains(where: { $0.participant == participant}) }
            let amountValue: Double? = expense.map {
                let weight = $0.participantsWeight.first(where: { $0.participant == participant })?.weight ?? 0
                return weight * $0.amount
            }
            let weightValue: Double? = expense.map {
                let weight = $0.participantsWeight.first(where: { $0.participant == participant })?.weight ?? 0
                return weight * totalWeight
            }

            participantsSection
                <<< CheckRow() {
                    $0.tag = "equally-\(participant.name)"
                    $0.title = participant.name
                    $0.value = (equallyValue ?? true)
                    $0.hidden = splitEquallyHidden
                    $0.cellUpdate { cell, _ in
                        cell.textLabel?.apply(style: .body(.darkBold))
                    }
                }
                <<< CustomDecimalRow() {
                    let tag = "amount-\(participant.name)"
                    $0.tag = tag
                    $0.title = participant.name
                    $0.value = amountValue
                    $0.hidden = splitAmountHidden
                    amountTags.append(tag)
                    $0.cellUpdate { cell, _ in
                        cell.textField.apply(style: .body(.dark))
                        cell.titleLabel?.apply(style: .body(.dark))
                    }
                }.onChange(amountUpdate)
                <<< CustomDecimalRow() {
                    let tag = "weight-\(participant.name)"
                    $0.tag = tag
                    $0.title = participant.name
                    $0.value = weightValue
                    $0.formatter = DecimalFormatter()
                    $0.useFormatterDuringInput = true
                    $0.hidden = splitWeightHidden
                    weightTags.append(tag)
                    $0.cellUpdate { cell, _ in
                        cell.textField.apply(style: .body(.dark))
                        cell.titleLabel?.apply(style: .body(.dark))
                    }
                }
        }

        let submitSection = Section()
            <<< ButtonRow() {
                $0.title = "Add new expense"
                $0.cellUpdate { cell, _ in
                    cell.textLabel?.font = Text.body(.dark).font
                }
            }.onCellSelection { [weak self] _, _ in
                    self?.addNewExpenseTapped()
            }
            <<< ButtonRow() {
                $0.title = "Save"
                $0.cellUpdate { cell, _ in
                    cell.textLabel?.font = Text.body(.dark).font
                }
            }.onCellSelection { [weak self] _, _ in
                    self?.saveButtonTapped()
            }

        form += [expenseSection, splitTypeSection, weightSection, participantsSection, submitSection]
    }

    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    private func saveButtonTapped() {
        guard form.validate().isEmpty else { return }

        guard let expense = createExpense() else { return }

        self.delegate?.didRequestSaveExpenseAndDismiss(expense, from: self)
    }

    private func addNewExpenseTapped() {
        guard form.validate().isEmpty else { return }

        guard let expense = createExpense() else { return }

        self.delegate?.didRequestSaveAndCreateNewExpense(expense, from: self)
    }

    private func createExpense() -> Expense? {
        guard let payer = form.stringRow(with: "payer-name")?.value.map({ Participant(name: $0, email: nil) }),
            let description = form.stringRow(with: "expense-description")?.value,
            let amount = form.doubleRow(with: "expense-amount")?.value else
        {
            return nil
        }

        guard !form.uBoolRow(with: "split-equally-switch").value! else {
            return Expense.equallySplited(with: split, payer: payer, participants: split.participants,
                                          description: description, amount: amount, id: expense?.id)
        }

        guard let segmentsRow = form.rowBy(tag: "weight-segments") as? SegmentedRow<Segment>,
            let segment = segmentsRow.value
            else {
                print("Something went wrong - couldn't find weight-segments value creating an expense")
                return nil
        }

        switch segment {
        case .Equally: return saveEquallySegment(payer: payer, description: description, amount: amount)
        case .Amount: return saveAmountSegment(payer: payer, description: description, amount: amount)
        case .Weight: return saveWeightSegment(payer: payer, description: description, amount: amount)
        }
    }

    private func saveEquallySegment(payer: Participant, description: String, amount: Double) -> Expense? {
        let participants = split.participants.filter { (form.rowBy(tag: "equally-\($0.name)") as? CheckRow)?.value == true }

        return Expense.equallySplited(with: split, payer: payer, participants: participants,
                                      description: description, amount: amount, id: expense?.id)
    }

    private func saveAmountSegment(payer: Participant, description: String, amount: Double) -> Expense? {
        let amounts = split.participants.compactMap { ($0, form.doubleRow(with: "amount-\($0.name)")?.value ?? 0) }

        return Expense.splitByAmount(with: split, payer: payer, amounts: amounts,
                                     description: description, amount: amount, id: expense?.id)
    }

    private func saveWeightSegment(payer: Participant, description: String, amount: Double) -> Expense? {
        let weights = split.participants.compactMap { ($0, form.doubleRow(with: "weight-\($0.name)")?.value ?? 0) }

        return Expense.splitByWeight(with: split, payer: payer, weights: weights,
                                     description: description, amount: amount, id: expense?.id)
    }

    // Override animations

    override func insertAnimation(forSections sections: [Section]) -> UITableView.RowAnimation {
        return .none
    }

    override func insertAnimation(forRows rows: [BaseRow]) -> UITableView.RowAnimation {
        return .none
    }

    override func deleteAnimation(forRows rows: [BaseRow]) -> UITableView.RowAnimation {
        return .none
    }

    override func deleteAnimation(forSections sections: [Section]) -> UITableView.RowAnimation {
        return .none
    }
}

final class CustomDecimalRow: _DecimalRow, RowType {

    var updated = false
}

private extension NewExpenseViewController.Segment {

    init?(splitType: Expense.SplitType) {
        switch splitType {
        case .equallyWithAll:
            return nil
        case .equallyCustom:
            self = .Equally
        case .byAmount:
            self = .Amount
        case .byWeight:
            self = .Weight
        }
    }
}
