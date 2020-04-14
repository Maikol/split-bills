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
        var name = ""
        var participants = ["", ""] // We require two empty participants

        var isValid: Bool {
            guard !name.isEmpty,
                let firstParticipant = participants.first, !firstParticipant.isEmpty,
                let secondParticipant = participants[safe: 1], !secondParticipant.isEmpty else {
                    return false
            }

            return true
        }
    }

    enum Event: Equatable {
        typealias Index = Int

        case onNameChange(String)
        case onParticipantNameChange(String, Index)
        case createSplit
        case didCreateSplit
        case addParticipant
    }
}

// MARK: - State Machine

extension NewSplitViewModel {

    func reduce(_ state: State, _ event: Event) -> State {
        switch event {
        case let .onNameChange(string):
            self.state.name = string
            return self.state
        case let .onParticipantNameChange(string, index):
            self.state.participants[index] = string
            return self.state
        case .createSplit:
            return state
        case .didCreateSplit:
            return state
        case .addParticipant:
            self.state.participants.append("")
            return self.state
        }
    }

    static func whenCreatingSplit(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            return input.filter { $0 == .createSplit }
                .flatMap { _ in DatabaseAPI.createSplit(name: state.name, participants: state.participants) }
                .map { Event.didCreateSplit }
                .eraseToAnyPublisher()
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}
