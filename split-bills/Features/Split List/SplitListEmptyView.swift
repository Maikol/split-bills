//
//  SplitListEmptyView.swift
//  split-bills
//
//  Created by Carlos DeElias on 6/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct SplitListEmptyView: View {

    var action: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack() {
                VStack() {
                    Label {
                        $0.numberOfLines = 0
                        $0.textAlignment = .center
                        $0.attributedText = NSAttributedString.emptyLabel
                    }
                    .offset(x: 0, y: -35)
                    HStack(alignment: .bottom) {
                        Spacer()
                        Image("down_arrow")
                            .offset(x: 0, y: -25)
                        PlusButton(action: action)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .offset(x: -24, y: -44)
    }
}

struct MainEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        SplitListEmptyView(action: {})
    }
}

private extension NSAttributedString {

    static let emptyLabel: NSAttributedString = {
        let attributedString = NSMutableAttributedString()

        let boldHeadingAttributes = [
            .foregroundColor: UIColor.dark,
            .font: UIFont.preferredFont(forTextStyle: .title2).bold()
            ] as [NSAttributedString.Key : Any]

        let boldAttributes = [
            .foregroundColor: UIColor.dark,
            .font: UIFont.preferredFont(forTextStyle: .title3).bold()
            ] as [NSAttributedString.Key : Any]

        let regularAttributes = [
            .foregroundColor: UIColor.dark,
            .font: UIFont.preferredFont(forTextStyle: .title3)
            ] as [NSAttributedString.Key : Any]

        attributedString.append(NSAttributedString(
            string: NSLocalizedString("root-controller.empty-view.text-1", comment: ""), attributes: regularAttributes))
        attributedString.append(NSAttributedString(
            string: "+", attributes: boldHeadingAttributes))
        attributedString.append(NSAttributedString(
            string: NSLocalizedString("root-controller.empty-view.text-2", comment: ""), attributes: regularAttributes))
        attributedString.append(NSAttributedString(
            string: NSLocalizedString("root-controller.empty-view.text-3", comment: ""), attributes: boldAttributes))
        attributedString.append(NSAttributedString(
            string: ".", attributes: regularAttributes))

        return attributedString
    }()
}
