//
//  MainView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 4/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Combine
import SwiftUI

struct EmptyView: View {
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
                        NavigationLink(destination: NewSplitView()) {
                            Image("plus_icon")
                                .renderingMode(.original)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct MainView: View {
    @EnvironmentObject var splitController: SplitController

    // TODO: There should be a better way
    init() {
        let style = UINavigationController.Style.default
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = style.backgroundColor.value
        appearance.titleTextAttributes = [.foregroundColor: style.textColor.value, .font: style.font]
        appearance.largeTitleTextAttributes = [.foregroundColor: style.textColor.value, .font: style.largeFont]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = style.textColor.value
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                if splitController.splits.isEmpty {
                    EmptyView() {
                        
                    }
                } else {
                    List(splitController.splits) { split in
                        NavigationLink(destination: SplitView(split: split)) {
                            Text(split.eventName)
                        }
                    }
                }
            }
            .offset(x: -24, y: -44)
            .background(ColorStyle.light.color)
            .edgesIgnoringSafeArea(.all)
            .navigationBarTitle("Split Bills")
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static let dataSource = SplitController()

    static var previews: some View {
        MainView().environmentObject(dataSource)
    }
}

private extension NSAttributedString {

    static let emptyLabel: NSAttributedString = {
        let attributedString = NSMutableAttributedString()

        let boldHeadingAttributes = [
            NSAttributedString.Key.foregroundColor: ColorStyle.dark.value,
            NSAttributedString.Key.font: TextStyle.heading2DarkBold.uiFont
            ] as [NSAttributedString.Key : Any]

        let boldAttributes = [
            NSAttributedString.Key.foregroundColor: ColorStyle.dark.value,
            NSAttributedString.Key.font: TextStyle.bodyLarge(.darkBold).uiFont
            ] as [NSAttributedString.Key : Any]

        let regularAttributes = [
            NSAttributedString.Key.foregroundColor: ColorStyle.dark.value,
            NSAttributedString.Key.font: TextStyle.bodyLarge(.dark).uiFont
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
