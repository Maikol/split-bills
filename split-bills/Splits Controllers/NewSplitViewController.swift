//
//  NewSplitViewController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import UIKit
import Eureka

protocol NewSplitViewControllerDelegate: class {
    func didCreateNewSplit(_ split: Split)
}

final class NewSplitViewController: FormViewController {

    weak var delegate: NewSplitViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        buildView()
        buildForm()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController!.isNavigationBarHidden = false
    }

    private func buildView() {
        title = "Bill"
        view.backgroundColor = .white
    }

    private func buildForm() {
        let eventSection = Section("Event info")
            <<< TextRow() {
                $0.tag = "event-name"
                $0.placeholder = "event name"
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }

        let partnersSection = MultivaluedSection(
                multivaluedOptions: [.Insert, .Delete],
                header: "Participants")
            {
                $0.tag = "participants"
                $0.addButtonProvider = { section in
                    return ButtonRow() {
                        $0.title = "Add participant"
                    }.cellUpdate { cell, row in
                        cell.textLabel?.textAlignment = .left
                    }
                }
                $0.multivaluedRowToInsertAt = { index in
                    return NameRow() {
                        $0.placeholder = "Participant \(index + 1)"
                    }
                }
                $0 <<< NameRow() {
                    $0.placeholder = "You"
                    $0.add(rule: RuleRequired())
                }
                $0 <<< NameRow() {
                    $0.placeholder = "Participant 1"
                    $0.add(rule: RuleRequired())
                }
            }

        let submitSection = Section()
            <<< ButtonRow() {
                $0.title = "Save"
            }.onCellSelection { [weak self] _, _ in
                self?.saveSplit()
            }

        form += [eventSection, partnersSection, submitSection]
    }

    private func saveSplit() {
        guard form.validate().isEmpty else { return }

        guard let split = Split(form: form) else { return }

        self.navigationController!.popViewController(animated: true)
        self.delegate?.didCreateNewSplit(split)
    }
}

private extension Split {

    init?(form: Eureka.Form) {
        let dic = form.values()
        guard let eventName = dic["event-name"] as? String else {
            return nil
        }

        guard let participantsSection = form.sectionBy(tag: "participants") as? MultivaluedSection, participantsSection.values().count > 1 else {
            return nil
        }

        self.eventName = eventName
        self.participants = participantsSection.values()
            .compactMap { $0 as? String }
            .map { Participant(name: $0, email: nil) }
    }
}
