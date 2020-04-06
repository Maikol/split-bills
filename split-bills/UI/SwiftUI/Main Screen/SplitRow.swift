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

    var body: some View {
        NavigationLink(destination: SplitView(split: split)) {
            Text(split.eventName)
        }
    }
}

struct SplitRow_Previews: PreviewProvider {
    static var previews: some View {
        SplitRow(split: Split(id: 0, eventName: "Test", participants: []))
    }
}
