//
//  NewSplitViewModel.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 13/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

final class NewSplitViewModel: ObservableObject {

    @Published private(set) var state = State()

    private var bag = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event, Never>()

    init() {
        Publishers.system(
            initial: state,
            reduce: self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenCreatingSplit(input: input.eraseToAnyPublisher()),
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

    func binding<U>(for keyPath: KeyPath<State, U>, event: @escaping (U) -> Event) -> Binding<U> {
        return Binding(
            get: {
                self.state[keyPath: keyPath]
            },
            set: {
                self.send(event: event($0))
            }
        )
    }
}

// MARK: - Inner Types

extension NewSplitViewModel {

    struct State: Equatable {

        struct Participant: Identifiable, Equatable, Hashable {
            let id = UUID()
            let index: Int
            var name = ""
            // Deleting items from the array was crashing Binding
            var removed = false
        }

        var name = ""
        // We require at least two participants for a split
        var requiredParticipants: [Participant] = [.init(index: 0), .init(index: 1)]
        var addedParticipants = [Participant]()

        var isValid: Bool {
            guard !name.isEmpty,
                let firstParticipant = requiredParticipants.first, !firstParticipant.name.isEmpty, !firstParticipant.removed,
                let secondParticipant = requiredParticipants[safe: 1], !secondParticipant.name.isEmpty, !secondParticipant.removed
            else {
                    return false
            }

            return true
        }
    }

    enum Event: Equatable {
        typealias Index = Int

        case onNameChange(String)
        case onRequiredParticipantNameChange(String, Index)
        case onAddedParticipantNameChange(String, Index)
        case createSplit
        case didCreateSplit
        case addParticipant
        case removeParticipant(Index)
    }
}

// MARK: - State Machine

extension NewSplitViewModel {

    func reduce(_ state: State, _ event: Event) -> State {
        switch event {
        case let .onNameChange(string):
            self.state.name = string
            return self.state
        case let .onRequiredParticipantNameChange(string, index):
            self.state.requiredParticipants[index].name = string
            return self.state
        case let .onAddedParticipantNameChange(string, index):
            self.state.addedParticipants[index].name = string
            return self.state
        case .createSplit:
            return state
        case .didCreateSplit:
            return state
        case .addParticipant:
            self.state.addedParticipants.append(.init(index: self.state.addedParticipants.count))
            return self.state
        case let .removeParticipant(index):
            self.state.addedParticipants[index].removed = true
            return self.state
        }
    }

    static func whenCreatingSplit(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            return input.filter { $0 == .createSplit }
                .flatMap { _ -> AnyPublisher<Void, Never> in
                    let requiredParticipants = state.requiredParticipants.map { $0.name }
                    let participants = state.addedParticipants.filter { !$0.name.isEmpty && !$0.removed }.map { $0.name }
                    return DatabaseAPI.createSplit(name: state.name, participants: requiredParticipants + participants)
                }
                .map { Event.didCreateSplit }
                .eraseToAnyPublisher()
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}
