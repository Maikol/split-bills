//
//  NewExpenseViewModel.swift
//  split-bills
//
//  Created by Carlos DeElias on 17/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

final class NewExpenseViewModel: ObservableObject {

    @Published private(set) var state: State

    private var bag = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event, Never>()

    init(splitId: SplitId) {
        state = .idle(splitId)
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(),
                Self.whenSaving(),
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &bag)
    }

    deinit {
        bag.removeAll()
    }

    func send(event: Event) {
        input.send(event)
    }

    func binding<U>(for keyPath: KeyPath<Expense, U>, event: @escaping (U) -> Event) -> Binding<U> {
        return Binding(
            get: {
                self.state.expense[keyPath: keyPath]
            },
            set: {
                self.send(event: event($0))
            }
        )
    }
}

// MARK: - Inner Types

extension NewExpenseViewModel {

    typealias SplitId = Int64

    enum State {
        case idle(SplitId)
        case loading(SplitId)
        case loaded(Split, Expense)
        case saving(Split, Expense)

        var expense: Expense {
            switch self {
            case let .loaded(_, expense):
                return expense
            default:
                return .init(split: Split(split: .empty))
            }
        }

        var isValid: Bool {
            switch self {
            case .idle, .loading, .saving:
                return false
            case let .loaded(_, expense):
                return expense.isValid
            }
        }
    }

    enum Event {
        typealias Index = Int

        case onAppear
        case onLoaded(Split, Expense)
        case onNameChange(String)
        case onPayerChange(Index)
        case onAmountChange(String)
        case onSplitEquallyChange(Bool)
        case onExpenseTypeChange(Index)
        case onExpenseTypeSelectionChange(Index, isSelected: Bool)
        case onExpenseTypeAmountChange(Index, amount: String)
        case onSaveExpense
        case expenseSaved
    }

    struct Split {
        let id: Int64
        let name: String
        let participants: [Participant]

        init(split: SplitDTO) {
            id = split.id
            name = split.name
            participants = split.participants.map { Participant(name: $0.name) }
        }
    }

    struct Participant {
        let name: String
    }

    struct Expense: Builder {
        var payerIndex = 0
        var name = ""
        var amount = ""
        var splitEqually = true
        var expenseTypeIndex = 0
        var participants: [Participant]
        var expenseTypeSelections: [ExpenseType.Selection]
        var expenseTypeAmounts: [ExpenseType.Amount]

        init(split: Split) {
            participants = split.participants
            expenseTypeSelections = split.participants.map { .init(participant: $0) }
            expenseTypeAmounts = split.participants.map { .init(participant: $0) }
        }
    }

    enum ExpenseType: Int, CaseIterable {

        struct Selection {
            let participant: Participant
            var isSelected = true
        }

        struct Amount {
            let participant: Participant
            var amount = ""
        }

        case equally
        case amount

        init(index: Int) {
            guard let type = NewExpenseViewModel.ExpenseType(rawValue: index) else {
                fatalError("Index out of bounds \(index)")
            }

            self = type
        }

        var localized: String {
            switch self {
            case .equally: return NSLocalizedString("expenses.new.split-differently.equally", comment: "")
            case .amount: return NSLocalizedString("expenses.new.split-differently.amount", comment: "")
            }
        }
    }
}

// MARK: - State Machine

extension NewExpenseViewModel {

    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case let .idle(splitId):
            switch event {
            case .onAppear:
                return .loading(splitId)
            default:
                return state
            }
        case .loading:
            switch event {
            case let .onLoaded(split, expense):
                return .loaded(split, expense)
            default:
                return state
            }
        case let .loaded(split, expense):
            switch event {
            case let .onNameChange(newName):
                return .loaded(split, expense.set(\.name, to: newName))
            case let .onPayerChange(newIndex):
                return .loaded(split, expense.set(\.payerIndex, to: newIndex))
            case let .onAmountChange(newAmount):
                return .loaded(split, expense.set(\.amount, to: newAmount))
            case let .onSplitEquallyChange(isSelected):
                return .loaded(split, expense.set(\.splitEqually, to: isSelected))
            case let .onExpenseTypeChange(newIndex):
                return  .loaded(split, expense.set(\.expenseTypeIndex, to: newIndex))
            case let .onExpenseTypeSelectionChange(participantIndex, isSelected):
                return .loaded(
                    split,
                    expense.set(\.expenseTypeSelections[participantIndex].isSelected, to: isSelected)
                )
            case let .onExpenseTypeAmountChange(participantIndex, newAmount):
                return .loaded(
                    split,
                    expense.set(\.expenseTypeAmounts[participantIndex].amount, to: newAmount)
                )
            case .onSaveExpense:
                return .saving(split, expense)
            default:
                return state
            }
        case .saving:
            return state
        }
    }

    static func whenLoading() -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .loading(itemId) = state else { return Empty().eraseToAnyPublisher() }

            return DatabaseAPI.split(withId: itemId)
                .compactMap { $0.map(Split.init) }
                .map { Event.onLoaded($0, .init(split: $0)) }
                .eraseToAnyPublisher()
        }
    }

    static func whenSaving() -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .saving(split, expense) = state, let amount = Double(expense.amount) else { return Empty().eraseToAnyPublisher() }

            let createExpense = DatabaseAPI.createExpense(
                splitId: split.id,
                name: expense.name,
                payerName: expense.payerName,
                amount: amount,
                weights: expense.weights,
                expenseTypeIndex: 0)
            return createExpense
                .map { Event.onSaveExpense }
                .eraseToAnyPublisher()
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}

// MARK: - Expense helpers

private extension NewExpenseViewModel.Expense {

    private var selectedExpenseType: NewExpenseViewModel.ExpenseType {
        NewExpenseViewModel.ExpenseType(index: expenseTypeIndex)
    }

    var isValid: Bool {
        guard !name.isEmpty,
            let amount = Double(amount), amount > 0 else
        {
            return false
        }

        if splitEqually {
            return true
        }

        switch selectedExpenseType {
        case .equally:
            return expenseTypeSelections.contains { $0.isSelected }
        case .amount:
            let doubleAmounts = expenseTypeAmounts.compactMap { Double($0.amount) }
            let participantsAmount = doubleAmounts.reduce(0, +)
            return fabs(1 - (amount/participantsAmount)) < 0.01
        }
    }

    var payerName: String {
        participants[payerIndex].name
    }

    typealias Weight = (name: String, weight: Double)

    var weights: [Weight] {


        if splitEqually {
            return splitEqually(with: participants)
        }

        switch selectedExpenseType {
        case .equally:
            let participants = expenseTypeSelections
                .filter { $0.isSelected }
                .map { $0.participant }
            return splitEqually(with: participants)
        case .amount:
            return splitByAmount
        }
    }

    private func splitEqually(with participants: [NewExpenseViewModel.Participant]) -> [Weight] {
        precondition(participants.count > 0, "We can calculate with no participants")
        let weight = 1 / Double(participants.count)
        return participants.map { (name: $0.name, weight: weight) }
    }

    private var splitByAmount: [Weight] {
        guard let amount = Double(amount) else {
            fatalError("Can't save an expense with a non double value")
        }

        precondition(amount > 0, "Expense needs to have a valid amoun")
        precondition(expenseTypeAmounts.count > 0, "There needs to be at least one participant")

        return expenseTypeAmounts.map { (name: $0.participant.name, weight: (Double($0.amount) ?? 0 / amount)) }
    }
}
