//
//  EditSplitViewModel.swift
//  split-bills
//
//  Created by Carlos DeElias on 15/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

final class EditSplitViewModel: ObservableObject {

    @Published private(set) var state: State

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

    deinit {
        bag.removeAll()
    }

    func send(event: Event) {
        input.send(event)
    }

    func binding<U>(for keyPath: KeyPath<Item, U>, event: @escaping (U) -> Event) -> Binding<U> {
        return Binding(
            get: {
                self.state.item[keyPath: keyPath]
            },
            set: {
                self.send(event: event($0))
            }
        )
    }
}

// MARK: - Inner Types

extension EditSplitViewModel {

    typealias ItemId = Int64

    enum State {
        case idle(ItemId)
        case loading(ItemId)
        case loaded(Item)

        var item: Item {
            switch self {
            case let .loaded(item):
                return item
            default:
                return .init(split: .empty)
            }
        }
    }

    enum Event: Equatable {
        typealias Index = Int

        case onAppear
        case onLoaded(Item)
        case onNameChange(String)
        case onParticipantNameChange(String, Index)
        case onAddParticipant
        case onRemoveParticipant(Index)
    }

    struct Item: Equatable, Builder {
        let id: ItemId
        var name: String
        var participants: [Participant]
        let originalParticipantsTotal: Int

        init(split: SplitDTO) {
            id = split.id
            name = split.name
            participants = split.participants.enumerated().map { Participant(index: $0.offset, name: $0.element.name) }
            originalParticipantsTotal = split.participants.count
        }

        var isValid: Bool {
            guard !name.isEmpty,
                let firstParticipant = participants.first, !firstParticipant.name.isEmpty, !firstParticipant.removed,
                let secondParticipant = participants[safe: 1], !secondParticipant.name.isEmpty, !secondParticipant.removed
            else {
                    return false
            }

            return true
        }
    }

    struct Participant: Identifiable, Equatable, Hashable {
        let id = UUID()
        let index: Int
        var name = ""
        var removed = false
    }
}

// MARK: - State Machine

extension EditSplitViewModel {

    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case let .idle(id):
            switch event {
            case .onAppear:
                return .loading(id)
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
            case let .onNameChange(newName):
                return .loaded(item.set(\.name, to: newName))
            case let .onParticipantNameChange(newName, index):
                return .loaded(item.set(\.participants[index].name, to: newName))
            case .onAddParticipant:
                var copy = item
                copy.participants.append(.init(index: item.participants.count))
                return .loaded(copy)
            case let .onRemoveParticipant(index):
                var copy = item
                copy.participants[index].removed = true
                return .loaded(copy)
            default:
                return state
            }
        }
    }

    static func whenLoading() -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .loading(itemId) = state else { return Empty().eraseToAnyPublisher() }

            return DatabaseAPI.split(withId: itemId)
                .compactMap { $0.map(Item.init) }
                .map(Event.onLoaded)
                .eraseToAnyPublisher()
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}
