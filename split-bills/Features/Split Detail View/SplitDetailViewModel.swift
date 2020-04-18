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

    init(splitId: SplitId, title: String, datasource: DataRequesting.Type = DatabaseAPI.self) {
        state = .idle(splitId, title: title)
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(datasource: datasource),
                Self.whenReloading(datasource: datasource),
                Self.whenRemoving(input: input.eraseToAnyPublisher(), datasource: datasource),
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

    typealias SplitId = Int64
    typealias ExpenseId = Int64

    enum State {
        case idle(SplitId, title: String)
        case loading(SplitId, title: String)
        case loaded(ListItem)
        case reloading(ListItem)

        var splitId: SplitId {
            switch self {
            case let .idle(splitId, _), let .loading(splitId, _):
                return splitId
            case let .loaded(item), let .reloading(item):
                return item.split.id
            }
        }

        var title: String {
            switch self {
            case let .loaded(item), let .reloading(item):
                return item.split.name
            case let .idle(_, title), let .loading(_, title):
                return title
            }
        }
    }

    enum Event {
        case onAppear
        case onReload
        case onLoaded(ListItem)
        case onRemoveExpense(ExpenseId)
        case onRemoveExpenses(offsets: IndexSet)

        fileprivate func expensesToRemove(from ids: [ExpenseId]) -> [ExpenseId] {
            switch self {
            case let .onRemoveExpense(expenseId) where ids.contains(expenseId):
                return [expenseId]
            case let .onRemoveExpenses(offsets):
                return offsets.map { ids[$0] }
            default:
                return []
            }
        }
    }

    struct ListItem {
        let split: SplitDisplayModel
        let expenses: [ExpenseDisplayModel]
    }

    struct Sheet: Identifiable {
        enum Style {
            case newExpense
            case expense(ExpenseId)
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

    static func whenLoading(datasource: DataRequesting.Type) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .loading(itemId, _) = state else { return Empty().eraseToAnyPublisher() }

            return datasource.split(withId: itemId)
                .compactMap { ($0, $0?.expenses) as? (SplitDTO, [ExpenseDTO]) }
                .map { ListItem(split: .init(split: $0.0), expenses: $0.1.map { .init(expense: $0) }) }
                .map(Event.onLoaded)
                .eraseToAnyPublisher()
        }
    }

    static func whenReloading(datasource: DataRequesting.Type) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .reloading(item) = state else { return Empty().eraseToAnyPublisher() }

            return datasource.split(withId: item.split.id)
                .compactMap { ($0, $0?.expenses) as? (SplitDTO, [ExpenseDTO]) }
                .map { ListItem(split: .init(split: $0.0), expenses: $0.1.map { .init(expense: $0) }) }
                .map(Event.onLoaded)
                .eraseToAnyPublisher()
        }
    }

    static func whenRemoving(input: AnyPublisher<Event, Never>, datasource: DataRequesting.Type) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .loaded(listItem) = state else { return Empty().eraseToAnyPublisher() }

            return input.map { $0.expensesToRemove(from: listItem.expenses.map { $0.id }) }
            .filter { !$0.isEmpty }
            .map { $0.map { datasource.removeExpense(withId: $0) } }
            .flatMap { Publishers.MergeMany($0) }
            .map { _ in Event.onReload }
            .eraseToAnyPublisher()
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}

// MARK: - Settle

extension SplitDetailViewModel.ListItem {

    var payments: [PaymentDisplayModel] {
        let paymentsValues = Dictionary(grouping: expenses) { $0.payer }
            .mapValues { $0.reduce(0) { return $0 + $1.amount } }

        var owingValues = [ParticipantDisplayModel: Double]()
        split.participants.forEach { participant in
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

    private func settle(_ values: [(key: ParticipantDisplayModel, value: Double)]) -> [PaymentDisplayModel] {
        guard values.count > 1 else {
            return []
        }

        guard let first = values.first, let last = values.last else {
            fatalError("something went wrong")
        }

        let sum = first.value + last.value
        var newValues = values.filter { $0.key != first.key && $0.key != last.key  }

        let payment = (sum < 0 ?
            PaymentDisplayModel(payer: last.key, receiver: first.key, amount: abs(first.value)) :
            PaymentDisplayModel(payer: last.key, receiver: first.key, amount: abs(last.value))
        )

        (sum < 0 ? newValues.append((last.key, sum)) : newValues.insert((first.key, sum), at: 0))

        return [payment] + settle(newValues)
    }
}
