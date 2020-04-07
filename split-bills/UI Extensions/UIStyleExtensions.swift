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
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = style.backgroundColor.value
        appearance.titleTextAttributes = [.foregroundColor: style.textColor.value, .font: style.font]
        appearance.largeTitleTextAttributes = [.foregroundColor: style.textColor.value, .font: style.largeFont]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.prefersLargeTitles = true

        navigationBar.tintColor = style.textColor.value
    }

    convenience init(rootViewController: UIViewController, style: Style) {
        self.init(rootViewController: rootViewController)

        apply(style: style)
    }
}

extension UITextField {

    struct Placeholder {
        let text: String
        let style: TextStyle
    }

    func apply(style: TextStyle, placeholder: Placeholder? = nil) {
        font = style.uiFont
        textColor = style.uiColor.value

        if let placeholder = placeholder {
            attributedPlaceholder = NSAttributedString(
                string: placeholder.text,
                attributes: [.font: placeholder.style.uiFont])
        }
    }
}

extension UILabel {

    func apply(style: TextStyle) {
        font = style.uiFont
        textColor = style.uiColor.value
    }
}

extension UINavigationController.Style {

    var backgroundColor: ColorStyle {
        switch self {
        case .default: return .brand
        }
    }

    var font: UIFont {
        switch self {
        case .default: return TextStyle.bodyLarge(.darkBold).uiFont
        }
    }

    var largeFont: UIFont {
        switch self {
        case .default: return TextStyle.headingWhiteBold.uiFont
        }
    }

    var textColor: ColorStyle {
        switch self {
        case .default: return .white
        }
    }
}
