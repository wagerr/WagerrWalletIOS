//
//  Checkbox.swift
//  breadwallet
//
//  Created by MIP on 22/12/2019.
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit

class CheckBox: UIButton {
    // Images
    let checkedImage = UIImage(named: "CircleCheckSolid")! as UIImage
    let uncheckedImage = UIImage(named: "Close")! as UIImage

    // Bool property
    var isChecked: Bool = false {
        didSet{
            if isChecked == true {
                self.setImage(checkedImage, for: UIControl.State.normal)
            } else {
                self.setImage(uncheckedImage, for: UIControlState.normal)
            }
        }
    }

    override func awakeFromNib() {
        self.addTarget(self, action:#selector(buttonClicked(sender:)), for: UIControl.Event.touchUpInside)
        self.isChecked = false
    }

    @objc func buttonClicked(sender: UIButton) {
        if sender == self {
            isChecked = !isChecked
        }
    }
}
