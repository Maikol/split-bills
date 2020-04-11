//
//  ViewExtensions.swift
//  split-bills
//
//  Created by Carlos DeElias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

extension Text {

    func apply(font: Font, color: Color, weight: Font.Weight = .regular) -> some View {
        self.font(font)
            .fontWeight(weight)
            .accentColor(color)
    }
}

extension View {

    func alignment(_ alignment: Alignment) -> some View {
        return self.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: alignment)
    }

    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }
}
