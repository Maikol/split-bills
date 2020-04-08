//
//  Button.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 13/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import UIKit

// Legacy
struct ButtonStyle {

    let textStyle: TextStyle
    let backgroundColor: ColorStyle
    let highlightedColor: ColorStyle?
    let selectedColor: ColorStyle?
    let disabledColor: ColorStyle?
}

extension UIButton {

    convenience init(title: String, style: ButtonStyle) {
        self.init()

        setTitle(title, for: .normal)

        titleLabel?.font = style.textStyle.uiFont

        setTitleColor(style.textStyle.uiColor.value, for: .normal)
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
