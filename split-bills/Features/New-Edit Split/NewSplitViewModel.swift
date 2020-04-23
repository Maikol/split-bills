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

    typealias State = SplitEditModel
    @Published private(set) var state: State = State()
        .set(\.existingParticipants, to: [.init(index: 0, name: ""), .init(index: 1, name: "")])

    private var bag = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event, Never>()

    init(datasource: DataRequesting = DatabaseAPI()) {
        Publishers.system(
            initial: state,
            reduce: self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenCreatingSplit(input: input.eraseToAnyPublisher(), datasource: datasource),
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
            return state.set(\.name, to: string)
        case let .onRequiredParticipantNameChange(string, index):
            return state.set(\.existingParticipants[index].name, to: string)
        case let .onAddedParticipantNameChange(string, index):
            return state.set(\.newParticipants[index].name, to: string)
        case .createSplit:
            return state
        case .didCreateSplit:
            return state
        case .addParticipant:
            var copy = self.state
            copy.newParticipants.append(.init(index: state.newParticipants.count))
            return copy
        case let .removeParticipant(index):
            return state.set(\.newParticipants[index].removed, to: true)
        }
    }

    static func whenCreatingSplit(input: AnyPublisher<Event, Never>, datasource: DataRequesting) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            let requiredParticipants = state.existingParticipants.map { $0.name }
            let newParticipants = state.newParticipants.filter { !$0.name.isEmpty && !$0.removed }.map { $0.name }
            let createSplitPublisher = datasource.createSplit(name: state.name, participants: requiredParticipants + newParticipants)

            return input.filter { $0 == .createSplit }
                .flatMap { _ in createSplitPublisher }
                .map { Event.didCreateSplit }
                .eraseToAnyPublisher()
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}
