//
//  NewSplitViewModel.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 4/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

final class NewSplitViewModel {

    let split: Split?

    unowned let coordinator: MainCoordinator

    init(split: Split?, coordinator: MainCoordinator) {
        self.split = split
        self.coordinator = coordinator
    }

    func createdNewSplit(name: String, participants: [Participant]) {
        guard let split = ApplicationController.shared.createEvent(name: name, participants: participants) else { return }

        coordinator.open(split: split)
    }
}
