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
        case saving(Item)

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
        case onExistingParticipantNameChange(String, Index)
        case onNewParticipantNameChange(String, Index)
        case onAddParticipant
        case onRemoveParticipant(Index)
        case onSaveSplit
        case splitSaved
    }

    struct Item: Equatable, Builder {
        let id: ItemId
        var name: String
        var existingParticipants: [Participant]
        var newParticipants = [Participant]()

        init(split: SplitDTO) {
            id = split.id
            name = split.name
            existingParticipants = split.participants.enumerated().map { Participant(index: $0.offset, name: $0.element.name) }
        }

        var isValid: Bool {
            guard !name.isEmpty,
                let firstParticipant = existingParticipants.first, !firstParticipant.name.isEmpty, !firstParticipant.removed,
                let secondParticipant = existingParticipants[safe: 1], !secondParticipant.name.isEmpty, !secondParticipant.removed
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
        // Deleting items from the array was crashing Binding
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
            case let .onExistingParticipantNameChange(newName, index):
                return .loaded(item.set(\.existingParticipants[index].name, to: newName))
            case let .onNewParticipantNameChange(newName, index):
                return .loaded(item.set(\.newParticipants[index].name, to: newName))
            case .onAddParticipant:
                var copy = item
                copy.newParticipants.append(.init(index: item.newParticipants.count))
                return .loaded(copy)
            case let .onRemoveParticipant(index):
                var copy = item
                copy.newParticipants[index].removed = true
                return .loaded(copy)
            case .onSaveSplit:
                return .saving(item)
            default:
                return state
            }
        case let .saving(item):
            switch event {
            case .splitSaved:
                return .idle(item.id)
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

    static func whenSaving() -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .saving(item) = state else { return Empty().eraseToAnyPublisher() }

            let newParticipantsFiltered = item.newParticipants.filter { !($0.removed || $0.name.isEmpty) }.map { $0.name }
            return DatabaseAPI.updateSplit(id: item.id, name: item.name, newParticipants: newParticipantsFiltered)
                .map { _ in Event.splitSaved }
                .eraseToAnyPublisher()
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}
