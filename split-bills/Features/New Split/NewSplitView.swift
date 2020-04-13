//
//  NewSplitView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 5/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct NewSplitView: View {

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var controller: DatabaseController

    @ObservedObject var viewModel: NewSplitViewModel

    @ObservedObject private var split = Split(
        id: 0,
        eventName: "",
        participants: [Participant(name: ""), Participant(name: "")]
    )

    var body: some View {
        NavigationView {
            content
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

    private var content: some View {
        KeyboardHost {
            Form {
                eventInfoView
                eventParticipantsView
                actionButtonView
            }
        }
    }

    private var eventInfoView: some View {
        Section(header: FormSectionHeader(key: "new-split-controller.event-info")) {
            TextField(
                "new-split-controller.event-name",
                text: viewModel.binding(for: \.name, event: NewSplitViewModel.Event.onNameChange))
        }
    }

    private var eventParticipantsView: some View {
        Section(header: FormSectionHeader(key: "new-split-controller.participants")) {
            TextField(
                "new-split-controller.participant-placeholder.you",
                text: viewModel.binding(for: \.participants[0]) { value in
                    NewSplitViewModel.Event.onParticipantNameChange(value, 0)
                }
            )

            TextField(
                "new-split-controller.participant-placeholder.participant-1",
                text: viewModel.binding(for: \.participants[1]) { value in
                    NewSplitViewModel.Event.onParticipantNameChange(value, 1)
                }
            )

            ForEach(2 ..< viewModel.state.participants.count, id: \.self) { index in
                SplitParticipantRow(
                    label: "Participant \(index)",
                    name: self.viewModel.binding(for: \.participants[index]) { value in
                       NewSplitViewModel.Event.onParticipantNameChange(value, index)
                   }
                ) {
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
    }

    private var actionButtonView: some View {
        Section {
            Button(action: createSplit) {
                Text("new-split-controller.save")
                    .font(.headline)
                    .accentColor(.link)
                    .alignment(.center)
            }
        }.disabled(!split.isValid)
    }

    private func deleteParticipant(at offsets: IndexSet) {
        split.participants.remove(atOffsets: offsets)
    }

    func createSplit() {
        viewModel.send(event: .createSplit)
        presentationMode.wrappedValue.dismiss()
    }
}

struct NewSplitView_Previews: PreviewProvider {
    static var previews: some View {
        NewSplitView(viewModel: NewSplitViewModel())
    }
}
