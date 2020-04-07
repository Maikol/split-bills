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
