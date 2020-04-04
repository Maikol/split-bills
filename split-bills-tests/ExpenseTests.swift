//
//  ExpenseTests.swift
//  split-bills-tests
//
//  Created by Carlos Miguel de Elias on 11/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import XCTest
@testable import split_bills

class ExpenseTests: XCTestCase {

    var participants: [Participant]!
    var split: Split!

    override func setUp() {
        super.setUp()

        participants = [participant1, participant2, participant3, participant4]
        split = Split(id: 1, eventName: "Test 1", participants: participants)
    }

    func testEquallySplited() {
        let expense = Expense.equallySplited(with: split, payer: participant1, participants: participants, description: "Expense test", amount: 100.0, id: nil)

        XCTAssertNotNil(expense)

        let payments = split.settle(expenses: [expense!])
        XCTAssertEqual(payments.count, 3)
        XCTAssertEqual(payments[0].amount, 25)
        XCTAssertEqual(payments[1].amount, 25)
        XCTAssertEqual(payments[2].amount, 25)

        let payers = payments.map { $0.payer }
        XCTAssert(payers.contains(participant2))
        XCTAssert(payers.contains(participant3))
        XCTAssert(payers.contains(participant4))
        XCTAssertFalse(payers.contains(participant1))

        let receivers = payments.map { $0.receiver }
        XCTAssert(receivers.contains(participant1))
        XCTAssertFalse(receivers.contains(participant2))
        XCTAssertFalse(receivers.contains(participant3))
        XCTAssertFalse(receivers.contains(participant4))
    }

    func testSplitByAmount() {
        let amounts1 = [(participant1, 20.0), (participant2, 40.0), (participant3, 15.0), (participant4, 30.0)]
        let expense1 = Expense.splitByAmount(with: split, payer: participant2, amounts: amounts1, description: "Expense amounts 1", amount: 105, id: nil)

        let amounts2 = [(participant1, 30.0), (participant2, 30.0), (participant3, 15.0), (participant4, 30.0)]
        let expense2 = Expense.splitByAmount(with: split, payer: participant3, amounts: amounts2, description: "Expense amounts 2", amount: 105, id: nil)

        XCTAssertNotNil(expense1)
        XCTAssertNotNil(expense2)

        let payments = split.settle(expenses: [expense1!, expense2!])
        XCTAssertEqual(payments.count, 3)

        let totalAmountPayments = payments.reduce(0) { return $0 + $1.amount }
        XCTAssertEqual(totalAmountPayments, 110.0)

        let payers = payments.map { $0.payer }
        XCTAssert(payers.contains(participant1))
        XCTAssert(payers.contains(participant4))
        XCTAssertFalse(payers.contains(participant2))
        XCTAssertFalse(payers.contains(participant3))

        let receivers = payments.map { $0.receiver }
        XCTAssert(receivers.contains(participant2))
        XCTAssert(receivers.contains(participant3))
        XCTAssertFalse(receivers.contains(participant1))
        XCTAssertFalse(receivers.contains(participant4))

        let participant1TotalPayment = payments.filter { $0.payer == participant1 }.reduce(0) { return $0 + $1.amount }
        XCTAssertEqual(participant1TotalPayment, 50)

        let participant4TotalPayment = payments.filter { $0.payer == participant4 }.reduce(0) { return $0 + $1.amount }
        XCTAssertEqual(participant4TotalPayment, 60)

        let participant2TotalReceived = payments.filter { $0.receiver == participant2 }.reduce(0) { return $0 + $1.amount }
        XCTAssertEqual(participant2TotalReceived, 35)

        let participant3TotalReceived = payments.filter { $0.receiver == participant3 }.reduce(0) { return $0 + $1.amount }
        XCTAssertEqual(participant3TotalReceived, 75)
    }

    func testSplitByWeight() {
        let weights1 = [(participant1, 2.0), (participant2, 6.0), (participant3, 8.0)]
        let expense1 = Expense.splitByWeight(with: split, payer: participant1, weights: weights1, description: "Expense weights 1", amount: 100, id: nil)

        let weights2 = [(participant1, 4.0), (participant2, 4.0), (participant3, 2.0)]
        let expense2 = Expense.splitByWeight(with: split, payer: participant3, weights: weights2, description: "Expense weights 2", amount: 85, id: nil)

        XCTAssertNotNil(expense1)
        XCTAssertNotNil(expense2)

        let payments = split.settle(expenses: [expense1!, expense2!])
        XCTAssertEqual(payments.count, 2)

        let totalAmountPayments = payments.reduce(0) { return $0 + $1.amount }
        XCTAssertEqual(totalAmountPayments, 71.5)

        let payers = payments.map { $0.payer }
        XCTAssert(payers.contains(participant2))
        XCTAssertFalse(payers.contains(participant1))
        XCTAssertFalse(payers.contains(participant3))

        let receivers = payments.map { $0.receiver }
        XCTAssert(receivers.contains(participant1))
        XCTAssert(receivers.contains(participant3))
        XCTAssertFalse(receivers.contains(participant2))

        let participant1TotalReceived = payments.filter { $0.receiver == participant1 }.reduce(0) { return $0 + $1.amount }
        XCTAssertEqual(participant1TotalReceived, 53.5)

        let participant2TotalPayment = payments.filter { $0.payer == participant2 }.reduce(0) { return $0 + $1.amount }
        XCTAssertEqual(participant2TotalPayment, 71.5)

        let participant3TotalReceived = payments.filter { $0.receiver == participant3 }.reduce(0) { return $0 + $1.amount }
        XCTAssertEqual(participant3TotalReceived, 18)
    }
}
