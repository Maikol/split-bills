//
//  System.swift
//  split-bills
//
//  Created by Carlos DeElias on 13/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Combine

extension Publishers {

    static func system<State, Event, Scheduler: Combine.Scheduler>(
        initial: State,
        reduce: @escaping (State, Event) -> State,
        scheduler: Scheduler,
        feedbacks: [Feedback<State, Event>]
    ) -> AnyPublisher<State, Never> {
        let state = CurrentValueSubject<State, Never>(initial)

        let events = feedbacks.map { feedback in feedback.run(state.eraseToAnyPublisher()) }

        return Deferred {
            Publishers.MergeMany(events)
                .receive(on: scheduler)
                .scan(initial, reduce)
                .handleEvents(receiveOutput: state.send)
                .receive(on: scheduler)
                .prepend(initial)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

public struct Mutation<State> {

    let mutate: (inout State) -> Void

    init<V>(keyPath: WritableKeyPath<State, V>, value: V) {
        self.mutate = { state in
            state[keyPath: keyPath] = value
        }
    }

    init(mutate: @escaping (inout State) -> Void) {
        self.mutate = mutate
    }
}
