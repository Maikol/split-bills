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

    func binding<U>(for keyPath: KeyPath<ExpenseEditModel, U>, event: @escaping (U) -> Event) -> Binding<U> {
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
        case loaded(SplitId, ExpenseId, ExpenseEditModel)
        case saving(ExpenseId, ExpenseEditModel)

        var expense: ExpenseEditModel {
            switch self {
            case let .loaded(_, _, expense):
                return expense
            default:
                return .init(participants: [])
            }
        }
    }

    enum Event {
        typealias Index = Int

        case onAppear
        case onLoaded(SplitId, ExpenseId, ExpenseEditModel)
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
            case let .onLoaded(splitId, expenseId, expense):
                return .loaded(splitId, expenseId, expense)
            default:
                return state
            }
        case let .loaded(splitId, expenseId, expense):
            switch event {
            case let .onNameChange(newName):
                return .loaded(splitId, expenseId, expense.set(\.name, to: newName))
            case let .onPayerChange(newIndex):
                return .loaded(splitId, expenseId, expense.set(\.payerIndex, to: newIndex))
            case let .onAmountChange(newAmount):
                return .loaded(splitId, expenseId, expense.set(\.amount, to: newAmount))
            case let .onSplitEquallyChange(isSelected):
                return .loaded(splitId, expenseId, expense.set(\.splitEqually, to: isSelected))
            case let .onExpenseTypeChange(newIndex):
                return  .loaded(splitId, expenseId, expense.set(\.expenseTypeIndex, to: newIndex))
            case let .onExpenseTypeSelectionChange(participantIndex, isSelected):
                return .loaded(
                    splitId, expenseId,
                    expense.set(\.expenseTypeSelections[participantIndex].isSelected, to: isSelected)
                )
            case let .onExpenseTypeAmountChange(participantIndex, newAmount):
                return .loaded(
                    splitId, expenseId,
                    expense.set(\.expenseTypeAmounts[participantIndex].amount, to: newAmount)
                )
            case .onSaveExpense:
                return .saving(expenseId, expense)
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

            let splitPublisher = DatabaseAPI.split(withId: splitId)
                .compactMap { $0 }
                .map(SplitDisplayModel.init)

            let expensePublisher = DatabaseAPI.expense(expenseId: expenseId)
                .compactMap { $0 }

            return Publishers.Zip(splitPublisher, expensePublisher)
                .map { ($0.0.id, $0.1.id, ExpenseEditModel(expense: $0.1, participants: $0.0.participants)) }
                .map(Event.onLoaded)
                .eraseToAnyPublisher()
        }
    }

    static func whenSaving() -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .saving(expenseId, expense) = state, let amount = Double(expense.amount) else { return Empty().eraseToAnyPublisher() }

            return DatabaseAPI.updateExpense(
                withId: expenseId,
                name: expense.name,
                payerName: expense.payerName,
                amount: amount,
                weights: expense.weights,
                expenseTypeIndex: <#T##DatabaseAPI.ExpenseTypeIndex#>)
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}
