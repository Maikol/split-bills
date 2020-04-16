//
//  SplitDetailViewModel.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 16/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import Combine

final class SplitDetailViewModel: ObservableObject {

    @Published private(set) var state: State
    @Published var activeSheet: Sheet?

    private var bag = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event, Never>()

    init(splitId: ItemId) {
        state = .idle(splitId)
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(),
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &bag)
    }

    func send(event: Event) {
        input.send(event)
    }

    func presentSheet(with style: Sheet.Style) {
        self.activeSheet = .init(style: style)
    }
}

// MARK: - Inner types

extension SplitDetailViewModel {

    typealias ItemId = Int64

    enum State {
        case idle(ItemId)
        case loading(ItemId)
        case loaded(SplitItem)
    }

    enum Event {
        case onAppear
        case onReload
        case onLoaded(SplitItem)
        case onRemoveExpense(Expense)
        case onRemoveExpenses(offsets: IndexSet)
        case onSelectExpense(Expense)
    }

    struct SplitItem {
        let id: ItemId
        let name: String
        let participants: [Participant]
        let expenses: [Expense]
        let payments = [Payment]()

        init(split: SplitDTO) {
            id = split.id
            name = split.name
            participants = split.participants.map { Participant(name: $0.name) }
            expenses = split.expenses.map { .init(expense: $0) }
        }
    }

    struct Participant: Identifiable, Equatable, Hashable {
        let id = UUID()
        let name: String
    }

    struct Expense: Identifiable {
        let id: Int64
        let name: String
        let payer: Participant
        let amount: Double
        let participantsWeight: [ExpenseWeight]
        let expenseType: ExpenseType

        init(expense: ExpenseDTO) {
            id = expense.id
            name = expense.name
            payer = .init(name: expense.payer.name)
            amount = expense.amount
            participantsWeight = expense.participantsWeight.map { .init(expenseWeight: $0) }
            expenseType = .init(expenseType: expense.expenseType)
        }
    }

    struct Payment: Identifiable {
        let id = UUID()
        let payer: Participant
        let receiver: Participant
        let amount: Double
    }

    struct ExpenseWeight {
        let participant: Participant
        let weight: Double

        init(expenseWeight: ExpenseWeightDTO) {
            participant = .init(name: expenseWeight.participant.name)
            weight = expenseWeight.weight
        }
    }

    enum ExpenseType: Int {
        case equallyWithAll
        case equallyCustom
        case byAmount

        init(expenseType: ExpenseTypeDTO) {
            switch expenseType {
            case .equallyWithAll:
                self = .equallyWithAll
            case .equallyCustom:
                self = .equallyCustom
            case .byAmount:
                self = .byAmount
            }
        }
    }

    struct Sheet: Identifiable {
        enum Style {
            case newExpense
            case expense(Expense)
        }

        let id = UUID()
        let style: Style
    }
}

// MARK: - State Machine

extension SplitDetailViewModel {

    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case let .idle(itemId):
            switch event {
            case .onAppear:
                return .loading(itemId)
            default:
                return state
            }
        case .loading:
            switch event {
            case let .onLoaded(item):
                return .loaded(item)
            default:
                return state
            }
        case .loaded:
            return state
        }
    }

    static func whenLoading() -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .loading(itemId) = state else { return Empty().eraseToAnyPublisher() }

            return DatabaseAPI.split(withId: itemId)
                .compactMap { $0.map(SplitItem.init) }
                .map(Event.onLoaded)
                .eraseToAnyPublisher()
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}
