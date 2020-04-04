//
//  Button.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 13/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import UIKit

struct ButtonStyle {

    let textStyle: Style
    let backgroundColor: Color
    let highlightedColor: Color?
    let selectedColor: Color?
    let disabledColor: Color?
}

extension UIButton {

    convenience init(title: String, style: ButtonStyle) {
        self.init()

        setTitle(title, for: .normal)

        titleLabel?.font = style.textStyle.font

        setTitleColor(style.textStyle.color.value, for: .normal)
        setTitleColor(style.highlightedColor?.value, for: .highlighted)
        setTitleColor(style.selectedColor?.value, for: .selected)
        setTitleColor(style.disabledColor?.value, for: .disabled)

        backgroundColor = style.backgroundColor.value
    }

    static func plusIcon() -> UIButton {
        let button = UIButton()
        button.setBackgroundImage(UIImage(named: "plus_icon")!, for: .normal)
        return button
    }
}
