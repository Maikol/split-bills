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

    init(splitId: ItemId, title: String) {
        state = .idle(splitId, title: title)
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(),
                Self.whenReloading(),
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
        case idle(ItemId, title: String)
        case loading(ItemId, title: String)
        case loaded(SplitItem)
        case reloading(SplitItem)

        var splitId: ItemId {
            switch self {
            case let .idle(splitId, _), let .loading(splitId, _):
                return splitId
            case let .loaded(splitItem), let .reloading(splitItem):
                return splitItem.id
            }
        }

        var title: String {
            switch self {
            case let .loaded(item), let .reloading(item):
                return item.name
            case let .idle(_, title), let .loading(_, title):
                return title
            }
        }
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
        case let .idle(itemId, title):
            switch event {
            case .onAppear:
                return .loading(itemId, title: title)
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
        case let .loaded(item):
            switch event {
            case .onReload:
                return .reloading(item)
            default:
                return state
            }
        case .reloading:
            switch event {
            case let .onLoaded(item):
                return .loaded(item)
            default:
                return state
            }
        }
    }

    static func whenLoading() -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .loading(itemId, _) = state else { return Empty().eraseToAnyPublisher() }

            return DatabaseAPI.split(withId: itemId)
                .compactMap { $0.map(SplitItem.init) }
                .map(Event.onLoaded)
                .eraseToAnyPublisher()
        }
    }

    static func whenReloading() -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .reloading(item) = state else { return Empty().eraseToAnyPublisher() }

            return DatabaseAPI.split(withId: item.id)
                .compactMap { $0.map(SplitItem.init) }
                .map(Event.onLoaded)
                .eraseToAnyPublisher()
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}

// MARK: - Settle

extension SplitDetailViewModel.SplitItem {

    var payments: [SplitDetailViewModel.Payment] {
        let paymentsValues = Dictionary(grouping: expenses) { $0.payer }
            .mapValues { $0.reduce(0) { return $0 + $1.amount } }

        var owingValues = [SplitDetailViewModel.Participant: Double]()
        participants.forEach { participant in
            let totalOwing = expenses.reduce(0.0) { result, expense in
                guard let weight = expense.participantsWeight.first(where: { $0.participant == participant }) else {
                    return result
                }

                return result + weight.weight * expense.amount
            }

            owingValues[participant] = totalOwing * (-1)
        }

        let mergedValues = paymentsValues.merging(owingValues, uniquingKeysWith: +).sorted { $0.value > $1.value }
        return settle(mergedValues).filter { $0.amount > 0.01 }
    }

    private func settle(_ values: [(key: SplitDetailViewModel.Participant, value: Double)]) -> [SplitDetailViewModel.Payment] {
        guard values.count > 1 else {
            return []
        }

        guard let first = values.first, let last = values.last else {
            fatalError("something went wrong")
        }

        let sum = first.value + last.value
        var newValues = values.filter { $0.key != first.key && $0.key != last.key  }

        let payment = (sum < 0 ?
            SplitDetailViewModel.Payment(payer: last.key, receiver: first.key, amount: abs(first.value)) :
            SplitDetailViewModel.Payment(payer: last.key, receiver: first.key, amount: abs(last.value))
        )

        (sum < 0 ? newValues.append((last.key, sum)) : newValues.insert((first.key, sum), at: 0))

        return [payment] + settle(newValues)
    }
}
