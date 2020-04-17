//
//  SplitListItemView.swift
//  split-bills
//
//  Created by Carlos DeElias on 6/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct SplitListItemView: View {

    var split: SplitDisplayModel
    var editAction: () -> Void
    var deleteAction: () -> Void

    var body: some View {
        Text(split.name)
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

struct SplitRow_Previews: PreviewProvider {
    static var previews: some View {
        SplitListItemView(split: .example, editAction: {}) {}
    }
}
