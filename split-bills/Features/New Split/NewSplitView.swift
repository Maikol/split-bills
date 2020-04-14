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

    @ObservedObject var viewModel: NewSplitViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .edgesIgnoringSafeArea(.bottom)
                KeyboardHost {
                    content
                }
            }
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
        Form {
            eventInfoView
            eventParticipantsView
            actionButtonView
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
                text: viewModel.binding(for: \.participants[0].name) { value in
                    NewSplitViewModel.Event.onParticipantNameChange(value, 0)
                }
            )

            TextField(
                "new-split-controller.participant-placeholder.participant-1",
                text: viewModel.binding(for: \.participants[1].name) { value in
                    NewSplitViewModel.Event.onParticipantNameChange(value, 1)
                }
            )

            ForEach(viewModel.state.participants.filter { $0.index > 1 && !$0.removed }.enumeratedArray(), id: \.element) { index, participant in
                SplitParticipantRow(
                    label: "Participant \(index + 3)",
                    name: self.viewModel.binding(for: \.participants[participant.index].name) { value in
                       NewSplitViewModel.Event.onParticipantNameChange(value, participant.index)
                   }
                ) {
                    self.viewModel.send(event: .removeParticipant(participant.index))
                }
            }
            Button(action: {
                self.viewModel.send(event: .addParticipant)
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
        }.disabled(!viewModel.state.isValid)
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
