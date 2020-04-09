//
//  PlusButton.swift
//  split-bills
//
//  Created by Carlos DeElias on 9/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct PlusButton: View {

    var action: () -> Void

    var body: some View {
        Button(action: {
            self.action()
        }) {
            Image("plus_icon")
                .renderingMode(.original)
        }.offset(x: -24, y: -44)
    }
}
