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

    init(splitId: SplitId, datasource: DataRequesting.Type = DatabaseAPI.self) {
        state = .idle(splitId)
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(datasource: datasource),
                Self.whenSaving(datasource: datasource),
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

extension NewExpenseViewModel {

    typealias SplitId = Int64

    enum State {
        case idle(SplitId)
        case loading(SplitId)
        case loaded(SplitId, ExpenseEditModel)
        case saving(SplitId, ExpenseEditModel)

        var expense: ExpenseEditModel {
            switch self {
            case let .loaded(_, expense):
                return expense
            default:
                return .init(participants: [])
            }
        }
    }

    enum Event {
        typealias Index = Int

        case onAppear
        case onLoaded(SplitId, ExpenseEditModel)
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

    struct Participant {
        let name: String
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
            case let .onLoaded(splitId, expense):
                return .loaded(splitId, expense)
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
        case let .saving(splitId, _):
            switch event {
            case .expenseSaved:
                return .idle(splitId)
            default:
                return state
            }
        }
    }

    static func whenLoading(datasource: DataRequesting.Type) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .loading(itemId) = state else { return Empty().eraseToAnyPublisher() }

            return datasource.split(withId: itemId)
                .compactMap { $0.map(SplitDisplayModel.init) }
                .map { Event.onLoaded($0.id, .init(participants: $0.participants)) }
                .eraseToAnyPublisher()
        }
    }

    static func whenSaving(datasource: DataRequesting.Type) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .saving(splitId, expense) = state, let amount = Double(expense.amount) else { return Empty().eraseToAnyPublisher() }

            let expenseData: DataRequesting.ExpenseData = (
                name: expense.name,
                payerName: expense.payerName,
                amount: amount,
                weights: expense.weights,
                expenseTypeIndex: expense.expenseTypeDTOIndex
            )
            return datasource.createExpense(splitId: splitId, expenseData: expenseData)
                .map { Event.expenseSaved }
                .eraseToAnyPublisher()
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}
