//
//  SplitListViewModel.swift
//  split-bills
//
//  Created by Carlos DeElias on 13/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import Combine

final class SplitListViewModel: ObservableObject {

    @Published private(set) var state = State.idle
    @Published var activeSheet: Sheet? = nil

    private var bag = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event, Never>()

    init(datasource: DataRequesting.Type = DatabaseAPI.self) {
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(datasource: datasource),
                Self.whenRemovingSplit(input: input.eraseToAnyPublisher(), datasource: datasource),
                Self.whenReloading(input: input.eraseToAnyPublisher(), datasource: datasource),
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

    func presentSheet(with style: Sheet.Style) {
        self.activeSheet = .init(style: style)
    }
}

// MARK: - Inner Types

extension SplitListViewModel {

    enum State {
        case idle
        case loading
        case loaded([SplitDisplayModel])
    }

    enum Event: Equatable {
        case onAppear
        case onSplitsLoaded([SplitDisplayModel])
        case onSplitsReloaded([SplitDisplayModel])
        case onRemoveSplit(SplitDisplayModel)
        case onRemoveSplits(offsets: IndexSet)
        case onReload

        fileprivate func splitsToRemove(from splits: [SplitDisplayModel]) -> [SplitDisplayModel] {
            switch self {
            case let .onRemoveSplit(split) where splits.contains(split):
                return [split]
            case let .onRemoveSplits(offsets):
                return offsets.map { splits[$0] }
            default:
                return []
            }
        }
    }

    struct Sheet: Identifiable {
        enum Style {
            case new
            case edit(SplitDisplayModel)
        }

        let id = UUID()
        let style: Style
    }
}

// MARK: - State Machine

extension SplitListViewModel {

    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case .idle:
            switch event {
            case .onAppear:
                return .loading
            default:
                return state
            }
        case .loading:
            switch event {
            case let .onSplitsLoaded(splits):
                return .loaded(splits)
            default:
                return state
            }
        case .loaded:
            switch event {
            case let .onSplitsReloaded(splits):
                return .loaded(splits)
            default:
                return state
            }
        }
    }

    static func whenLoading(datasource: DataRequesting.Type) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loading = state else { return Empty().eraseToAnyPublisher() }

            return datasource.splits()
                .map { $0.map(SplitDisplayModel.init) }
                .map(Event.onSplitsLoaded)
                .eraseToAnyPublisher()
        }
    }

    static func whenRemovingSplit(input: AnyPublisher<Event, Never>, datasource: DataRequesting.Type) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .loaded(items) = state else { return Empty().eraseToAnyPublisher() }

            return input.map { $0.splitsToRemove(from: items) }
                .filter { !$0.isEmpty }
                .map { $0.map { datasource.removeSplit(id: $0.id) } }
                .flatMap { Publishers.MergeMany($0) }
                // TODO: Should be a different state for reloading
                .flatMap { _ in datasource.splits() }
                .map { $0.map(SplitDisplayModel.init) }
                .map(Event.onSplitsReloaded)
                .eraseToAnyPublisher()
        }
    }

    static func whenReloading(input: AnyPublisher<Event, Never>, datasource: DataRequesting.Type) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loaded = state else { return Empty().eraseToAnyPublisher() }

            return input.filter { $0 == .onReload }
                .flatMap { _ in datasource.splits() }
                .map { $0.map(SplitDisplayModel.init) }
                .map(Event.onSplitsReloaded)
                .eraseToAnyPublisher()
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}
