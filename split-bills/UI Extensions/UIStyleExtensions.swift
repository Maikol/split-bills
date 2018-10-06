//
//  UIStyleExtensions.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 19/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationController {

    enum Style {
        case `default`
    }

    func apply(style: Style) {
        navigationBar.barTintColor = style.backgroundColor.value
        navigationBar.tintColor = style.textColor.value
        navigationBar.titleTextAttributes = [.foregroundColor: style.textColor.value, .font: style.font]

        navigationBar.largeTitleTextAttributes = [.foregroundColor: style.textColor.value, .font: style.largeFont]

        navigationBar.prefersLargeTitles = true
    }

    convenience init(rootViewController: UIViewController, style: Style) {
        self.init(rootViewController: rootViewController)

        apply(style: style)
    }
}

extension UITextField {

    struct Placeholder {
        let text: String
        let style: Text
    }

    func apply(style: Text, placeholder: Placeholder? = nil) {
        font = style.font
        textColor = style.color.value

        if let placeholder = placeholder {
            attributedPlaceholder = NSAttributedString(
                string: placeholder.text,
                attributes: [.font: placeholder.style.font])
        }
    }
}

extension UILabel {

    func apply(style: Text) {
        font = style.font
        textColor = style.color.value
    }
}

private extension UINavigationController.Style {

    var backgroundColor: Color {
        switch self {
        case .default: return .brand
        }
    }

    var font: UIFont {
        switch self {
        case .default: return Text.bodyLarge(.darkBold).font
        }
    }

    var largeFont: UIFont {
        switch self {
        case .default: return Text.headingWhiteBold.font
        }
    }

    var textColor: Color {
        switch self {
        case .default: return .white
        }
    }
}
