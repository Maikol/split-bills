//
//  EditSplitView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 11/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct EditSplitView: View {

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var controller: DatabaseController

    @ObservedObject var split: Split

    var exisintgParticipansCount: Int

    var body: some View {
        NavigationView {
            KeyboardHost {
                Form {
                    Section(header: FormSectionHeader(key: "new-split-controller.event-info")) {
                        TextField("new-split-controller.event-name", text: $split.eventName)
                    }

                    Section(header: FormSectionHeader(key: "new-split-controller.participants")) {
                        ForEach(0 ..< exisintgParticipansCount, id: \.self) { index in
                            TextField("Participant \(index + 1)", text: self.$split.participants[index].name)
                        }
                        ForEach(exisintgParticipansCount ..< split.participants.count, id: \.self) { index in
                            SplitParticipantRow(
                                label: "Participant \(index)",
                                name: self.$split.participants[index].name)
                            {
                                self.split.participants.remove(at: index)
                            }
                        }
                        Button(action: {
                            self.split.participants.append(Participant(name: ""))
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .accentColor(.green)
                                Text("new-split-controller.add-participant")
                                    .apply(font: .body, color: .link)
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
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("split-controller.cancel")
                        .apply(font: .body, color: .white)
                }
            )
        }
    }

    func saveSplit() {
        split.participants.removeAll { $0.name.isEmpty }
        controller.update(split: split)
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct SplitEditView_Previews: PreviewProvider {
    static var previews: some View {
        EditSplitView(split: .example, exisintgParticipansCount: 2)
    }
}