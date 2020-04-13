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
    @Published var sheet: Sheet? = nil

    private var bag = Set<AnyCancellable>()

    private let input = PassthroughSubject<Event, Never>()

    init() {
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(),
                Self.whenRemovingSplit(input: input.eraseToAnyPublisher()),
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
}

// MARK: - Inner Types

extension SplitListViewModel {

    enum State {
        case idle
        case loading
        case loaded([ListItem])
    }

    enum Event {
        case onAppear
        case onSplitsLoaded([ListItem])
        case onRemoveSplit(ListItem)
        case onReload

        var removedSplit: ListItem? {
            switch self {
            case let .onRemoveSplit(item):
                return item
            default:
                return nil
            }
        }
    }

    struct Sheet: Identifiable {

        enum Style {
            case new
            case edit(ListItem)
        }

        let id = UUID()
        let style: Style
    }

    struct ListItem: Identifiable {
        let id: Int64
        let name: String
        let participants: [String]

        init(split: SplitDTO) {
            id = split.id
            name = split.name
            participants = split.participants.map { $0.name }
        }
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
            case .onReload:
                return .loading
            default:
                return state
            }
        }
    }

    static func whenLoading() -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loading = state else { return Empty().eraseToAnyPublisher() }

            return DatabaseAPI.splits()
                .map { $0.map(ListItem.init) }
                .map(Event.onSplitsLoaded)
                .eraseToAnyPublisher()
        }
    }

    static func whenRemovingSplit(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loaded = state else { return Empty().eraseToAnyPublisher() }

            return input.compactMap { $0.removedSplit }
                .flatMap { DatabaseAPI.removeSplit(id: $0.id, name: $0.name) }
                .map { Event.onReload }
                .eraseToAnyPublisher()
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}

#if DEBUG
extension SplitListViewModel.ListItem {
    static let example = SplitListViewModel.ListItem(split: .example)
}
#endif
