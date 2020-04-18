//
//  ParticipantSelectRow.swift
//  split-bills
//
//  Created by Carlos DeElias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct ParticipantSelectRow: View {

    let name: String
    @Binding var isSelected: Bool

    var body: some View {
        Button(action: {
            self.isSelected.toggle()
        }) {
            HStack {
                Text(name)
                    .apply(font: .body, color: .dark, weight: .bold)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
            }
        }.foregroundColor(.primary)
    }
}

struct ParticipantSelectRow_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantSelectRow(name: "test", isSelected: .constant(true))
            .previewLayout(PreviewLayout.sizeThatFits)
    }
}
