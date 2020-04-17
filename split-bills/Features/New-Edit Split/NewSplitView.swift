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
                KeyboardHost {
                    content
                }
            }.edgesIgnoringSafeArea(.bottom)
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
            requiredParticipantTextField(withIndex: 0)
            requiredParticipantTextField(withIndex: 1)
            dynamicListOfParticipants
            addParticipantButton
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

    private func requiredParticipantTextField(withIndex index: Int) -> some View {
        TextField(
            "new-split-controller.participant-placeholder.participant-1",
            text: viewModel.binding(for: \.requiredParticipants[index].name) { value in
                NewSplitViewModel.Event.onRequiredParticipantNameChange(value, index)
            }
        )
    }

    private var dynamicListOfParticipants: some View {
        ForEach(0 ..< viewModel.state.activeAddedParticipants.count, id: \.self) { index in
            self.addedParticipantView(
                withIndex: index + self.viewModel.state.requiredParticipants.count + 1,
                participant: self.viewModel.state.activeAddedParticipants[index])
        }
    }

    private func addedParticipantView(withIndex index: Int, participant: NewSplitViewModel.State.Participant) -> some View {
        SplitParticipantRow(
            label: "Participant \(index)",
            name: self.viewModel.binding(for: \.addedParticipants[participant.index].name) { value in
               NewSplitViewModel.Event.onAddedParticipantNameChange(value, participant.index)
           }
        ) {
            self.viewModel.send(event: .removeParticipant(participant.index))
        }
    }

    private var addParticipantButton: some View {
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

    func createSplit() {
        viewModel.send(event: .createSplit)
        presentationMode.wrappedValue.dismiss()
    }
}

extension NewSplitViewModel.State {

    var activeAddedParticipants: [NewSplitViewModel.State.Participant] {
        addedParticipants.filter { !$0.removed }
    }
}

struct NewSplitView_Previews: PreviewProvider {
    static var previews: some View {
        NewSplitView(viewModel: NewSplitViewModel())
    }
}
