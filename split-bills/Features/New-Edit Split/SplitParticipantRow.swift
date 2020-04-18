//
//  SplitParticipantRow.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 11/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct SplitParticipantRow: View {

    var label: String
    @Binding var name: String
    var deleteAction: () -> Void

    var body: some View {
        HStack {
            Button(action: deleteAction) {
                Image(systemName: "minus.circle.fill")
                    .accentColor(.red)
            }
            FirstResponderTextField(label: label, text: $name, isFirstResponder: true)
        }
    }
}

struct SplitParticipantRow_Previews: PreviewProvider {
    static var previews: some View {
        SplitParticipantRow(label: "Test", name: .constant("Bob")) {}
    }
}
