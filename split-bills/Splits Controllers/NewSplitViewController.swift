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

    private func buildView() {
        title = "New split"
        view.backgroundColor = .white

        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
        self.navigationItem.rightBarButtonItem = doneButton
    }

    private func buildForm() {
        let eventSection = Section("Event info")
            <<< TextRow() {
                $0.tag = "event-name"
                $0.placeholder = "event name"
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }

        let infoSection = Section("Your info")
            <<< TextRow() {
                $0.tag = "name"
                $0.placeholder = "your name"
                $0.add(rule: RuleRequired())
            }
            <<< TextRow() {
                $0.tag = "email"
                $0.placeholder = "your email (optional)"
                $0.add(rule: RuleEmail())
            }

        let partnersSection = MultivaluedSection(
                multivaluedOptions: [.Insert, .Delete],
                header: "Participants")
            {
                $0.tag = "participants"
                $0.addButtonProvider = { section in
                    return ButtonRow() {
                        $0.title = "Add new person"
                    }.cellUpdate { cell, row in
                            cell.textLabel?.textAlignment = .left
                    }
                }
                $0.multivaluedRowToInsertAt = { index in
                    return NameRow() {
                        $0.tag = "person-\(index+1)"
                        $0.placeholder = "Person \(index + 1)"
                    }
                }
                $0 <<< NameRow() {
                    $0.tag = "person-1"
                    $0.placeholder = "Person 1"
                    $0.add(rule: RuleRequired())
                }
            }

        form += [eventSection, infoSection, partnersSection]
    }

    @objc private func doneButtonTapped() {
        guard form.validate().isEmpty else { return }

        guard let split = Split(form: form) else { return }

        self.navigationController!.popViewController(animated: true)
        self.delegate?.didCreateNewSplit(split)
    }
}

private extension Split {

    init?(form: Eureka.Form) {
        let dic = form.values()
        guard let eventName = dic["event-name"] as? String, let name = dic["name"] as? String else {
            return nil
        }

        guard let participantsSection = form.sectionBy(tag: "participants") as? MultivaluedSection else {
            return nil
        }

        self.eventName = eventName
        self.name = name
        self.email = dic["email"] as? String
        self.participants = [Participant(name: name, email: nil)] + participantsSection.values().compactMap { $0 as? String }.map { Participant(name: $0, email: nil) }
    }
}
