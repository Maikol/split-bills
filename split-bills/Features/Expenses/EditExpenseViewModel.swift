//
//  EditExpenseViewModel.swift
//  split-bills
//
//  Created by Carlos DeElias on 17/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

final class EditExpenseViewModel: ObservableObject {

    @Published private(set) var state: State

    private var bag = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event, Never>()

    init(splitId: SplitId, expenseId: ExpenseId) {
        state = .idle(splitId: splitId, expenseId: expenseId)
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

extension EditExpenseViewModel {

    typealias SplitId = Int64
    typealias ExpenseId = Int64

    enum State {
        case idle(splitId: SplitId, expenseId: ExpenseId)
        case loading(splitId: SplitId, expenseId: ExpenseId)
        case loaded(Split, Expense)
        case saving(Split, Expense)

        var expense: Expense {
            switch self {
            case let .loaded(_, expense):
                return expense
            default:
                return .init(split: .empty, expense: .empty)
            }
        }

        var isValid: Bool {
            switch self {
            case .idle, .loading, .saving:
                return false
            case let .loaded(_, expense):
                return false
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
        case onRemoveExpense
        case expenseDismissed
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
        let id: Int64
        var payerIndex = 0
        var name = ""
        var amount = ""
        var splitEqually = true
        var expenseTypeIndex = 0
        var participants: [Participant]
        var expenseTypeSelections: [ExpenseType.Selection]
        var expenseTypeAmounts: [ExpenseType.Amount]

        init(split: SplitDTO, expense: ExpenseDTO) {
            id = expense.id
            participants = split.participants.map { Participant(name: $0.name) }
            // TODO: recheck
            payerIndex = split.participants.firstIndex { $0.name == expense.payer.name }!
            name = expense.name
            amount = String(format:"%.2f", expense.amount)
            splitEqually = (expense.expenseType == .equallyWithAll)
            expenseTypeIndex = (expense.expenseType == .byAmount ? 1 : 0)
            expenseTypeSelections = split.participants.map { participant in
                .init(participant: .init(name: participant.name), isSelected: expense.participantsWeight.contains { $0.participant == participant })
            }
            expenseTypeAmounts = split.participants.map { participant in
                let storedAmount = expense.participantsWeight.first { $0.participant == participant }.map { String($0.weight * expense.amount) } ?? ""
                return .init(participant: .init(name: participant.name), amount: storedAmount)
            }
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
            guard let type = EditExpenseViewModel.ExpenseType(rawValue: index) else {
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

extension EditExpenseViewModel {

    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case let .idle(splitId, expenseId):
            switch event {
            case .onAppear:
                return .loading(splitId: splitId, expenseId: expenseId)
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
            guard case let .loading(splitId, expenseId) = state else { return Empty().eraseToAnyPublisher() }

            return Publishers.Zip(DatabaseAPI.split(withId: splitId), DatabaseAPI.expense(expenseId: expenseId))
                .compactMap { $0 as? (SplitDTO, ExpenseDTO) }
                .map { (Split(split: $0.0), Expense(split: $0.0, expense: $0.1)) }
                .map(Event.onLoaded)
                .eraseToAnyPublisher()
        }
    }

    static func whenSaving() -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .saving(split, expense) = state, let amount = Double(expense.amount) else { return Empty().eraseToAnyPublisher() }

            return Empty().eraseToAnyPublisher()
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}
