//
//  ViewExtensions.swift
//  split-bills
//
//  Created by Carlos DeElias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

extension Text {

    func apply(style: TextStyle) -> some View {
        self.font(style.font)
            .accentColor(style.color)
    }
}

extension View {

    func alignment(_ alignment: Alignment) -> some View {
        return self.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: alignment)
    }
}
