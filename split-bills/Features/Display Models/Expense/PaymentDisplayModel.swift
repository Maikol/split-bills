//
//  PaymentDisplayModel.swift
//  split-bills
//
//  Created by Carlos DeElias on 17/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Foundation

struct PaymentDisplayModel: Identifiable {
    let id = UUID()
    let payer: ParticipantDisplayModel
    let receiver: ParticipantDisplayModel
    let amount: Double
}
