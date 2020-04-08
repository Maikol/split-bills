//
//  SharedViews.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 5/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct FormSectionHeader: View {
    var key: LocalizedStringKey

    var body: some View {
        Text(key)
            .apply(style: .bodySmall(.darkBold))
            .padding(.top)
    }
}

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
