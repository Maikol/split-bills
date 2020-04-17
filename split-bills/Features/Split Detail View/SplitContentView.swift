//
//  SplitContentView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 8/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct SplitContentView: View {

    @EnvironmentObject var controller: DatabaseController

    @ObservedObject var split: Split

    var expenseTappedAction: (Expense) -> Void

    var body: some View {
        
    }

    
}

private extension Split {

    var payments: [Payment] {
        settle(expenses: expenses).sorted { $0.payer.name < $1.payer.name }
    }
}

struct SplitContentView_Previews: PreviewProvider {
    static var previews: some View {
        SplitContentView(split: .example, expenseTappedAction: { _ in })
    }
}
