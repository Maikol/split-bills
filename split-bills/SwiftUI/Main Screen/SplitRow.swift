//
//  SplitRow.swift
//  split-bills
//
//  Created by Carlos DeElias on 6/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct SplitRow: View {

    var split: Split
    var editAction: () -> Void
    var deleteAction: () -> Void

    var body: some View {
        NavigationLink(destination: SplitView(split: split)) {
            Text(split.eventName)
                .apply(font: .body, color: .dark)
                .contextMenu {
                    Button(action: {
                        self.editAction()
                    }) {
                        Text("Edit")
                        Image(systemName: "pencil")
                    }
                    Button(action: {
                        self.deleteAction()
                    }) {
                        Text("Delete")
                            .foregroundColor(.error) // Not working
                        Image(systemName: "trash")
                    }.foregroundColor(.primary)
            }
        }
    }
}

struct SplitRow_Previews: PreviewProvider {
    static var previews: some View {
        SplitRow(split: Split(id: 0, eventName: "Test", participants: []), editAction: {}) {}
    }
}
