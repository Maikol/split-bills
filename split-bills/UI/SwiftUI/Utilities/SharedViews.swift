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
            .font(TextStyle.bodySmall(.darkBold).font)
            .foregroundColor(ColorStyle.dark.color)
            .padding(.top)
    }
}

extension Text {

    func apply(style: TextStyle) -> some View {
        self.font(style.font)
            .accentColor(style.color.color)
    }
}

extension View {

    func alignment(_ alignment: Alignment) -> some View {
        return self.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: alignment)
    }
}
