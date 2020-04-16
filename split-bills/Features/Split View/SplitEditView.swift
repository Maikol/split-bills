//
//  SplitEditView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 11/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct EditSplitView: View {

    @EnvironmentObject var controller: ApplicationController

    @ObservedObject var split: Split

    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            KeyboardHost {
                Form {
                    Section(header: FormSectionHeader(key: "new-split-controller.event-info")) {
                        TextField("new-split-controller.event-name", text: $split.eventName)
                    }

                    Section(header: FormSectionHeader(key: "new-split-controller.participants")) {
                        ForEach(0 ..< split.participants.count, id: \.self) { index in
                            TextField("Participant \(index + 1)", text: self.$split.participants[index].name)
                        }
                        Button(action: {
                            self.split.participants.append(Participant(name: ""))
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .accentColor(.green)
                                Text("new-split-controller.add-participant")
                                    .apply(style: .body(.link))
                            }
                        }
                    }

                    Section {
                        Button(action: saveSplit) {
                            Text("new-split-controller.save")
                                .font(.headline)
                                .accentColor(.link)
                                .alignment(.center)
                        }
                    }.disabled(!split.isValid)
                }
            }
            .background(Color.background)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitle(Text("new-split-controller.title"), displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: {
                    self.isPresented.toggle()
                }) {
                    Text("split-controller.cancel")
                        .apply(style: .body(.white))
                }
            )
        }
    }

    func saveSplit() {
        app
    }
}

struct SplitEditView_Previews: PreviewProvider {
    static var previews: some View {
        EditSplitView(split: .example, isPresented: .constant(true))
    }
}
