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

    init(splitId: SplitId, datasource: DataRequesting = DatabaseAPI()) {
        state = .idle(splitId)
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(datasource: datasource),
                Self.whenSaving(datasource: datasource),
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

    func binding<U>(for keyPath: KeyPath<SplitEditModel, U>, event: @escaping (U) -> Event) -> Binding<U> {
        return Binding(
            get: {
                self.state.split[keyPath: keyPath]
            },
            set: {
                self.send(event: event($0))
            }
        )
    }
}

// MARK: - Inner Types

extension EditSplitViewModel {

    typealias SplitId = Int64

    enum State {
        case idle(SplitId)
        case loading(SplitId)
        case loaded(SplitId, SplitEditModel)
        case saving(SplitId, SplitEditModel)

        var split: SplitEditModel {
            switch self {
            case let .loaded(_, split):
                return split
            default:
                return .init()
            }
        }
    }

    enum Event: Equatable {
        typealias Index = Int

        case onAppear
        case onLoaded(SplitEditModel)
        case onNameChange(String)
        case onExistingParticipantNameChange(String, Index)
        case onNewParticipantNameChange(String, Index)
        case onAddParticipant
        case onRemoveParticipant(Index)
        case onSaveSplit
        case splitSaved
    }
}

// MARK: - State Machine

extension EditSplitViewModel {

    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case let .idle(splitId):
            switch event {
            case .onAppear:
                return .loading(splitId)
            default:
                return state
            }
        case let .loading(splitId):
            switch event {
            case let .onLoaded(item):
                return .loaded(splitId, item)
            default:
                return state
            }
        case let .loaded(splitId, split):
            switch event {
            case let .onNameChange(newName):
                return .loaded(splitId, split.set(\.name, to: newName))
            case let .onExistingParticipantNameChange(newName, index):
                return .loaded(splitId, split.set(\.existingParticipants[index].name, to: newName))
            case let .onNewParticipantNameChange(newName, index):
                return .loaded(splitId, split.set(\.newParticipants[index].name, to: newName))
            case .onAddParticipant:
                var copy = split
                copy.newParticipants.append(.init(index: split.newParticipants.count))
                return .loaded(splitId, copy)
            case let .onRemoveParticipant(index):
                return .loaded(splitId, split.set(\.newParticipants[index].removed, to: true))
            case .onSaveSplit:
                return .saving(splitId, split)
            default:
                return state
            }
        case let .saving(splitId, _):
            switch event {
            case .splitSaved:
                return .idle(splitId)
            default:
                return state
            }
        }
    }

    static func whenLoading(datasource: DataRequesting) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .loading(itemId) = state else { return Empty().eraseToAnyPublisher() }

            return datasource.split(withId: itemId)
                .compactMap { $0.map(SplitEditModel.init) }
                .map(Event.onLoaded)
                .eraseToAnyPublisher()
        }
    }

    static func whenSaving(datasource: DataRequesting) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case let .saving(splitId, split) = state else { return Empty().eraseToAnyPublisher() }

            let newParticipantsFiltered = split.newParticipants.filter { !($0.removed || $0.name.isEmpty) }.map { $0.name }
            return datasource.updateSplit(id: splitId, name: split.name, newParticipants: newParticipantsFiltered)
                .map { _ in Event.splitSaved }
                .eraseToAnyPublisher()
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}
