//
//  WhiteNumberPad.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-03-16.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit

class WhiteNumberPad : GenericPinPadCell {

    override func setAppearance() {

        if text == "0" {
            topLabel.isHidden = true
            centerLabel.isHidden = false
        } else {
            topLabel.isHidden = false
            centerLabel.isHidden = true
        }

        if isHighlighted {
            backgroundColor = .secondaryShadow
            topLabel.textColor = .grayText
            centerLabel.textColor = .grayText
            sublabel.textColor = .grayText
        } else {
            if text == "" || text == deleteKeyIdentifier {
                backgroundColor = .whiteBackground
                imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = .grayText
            } else {
                backgroundColor = .whiteBackground
                topLabel.textColor = .grayText
                centerLabel.textColor = .grayText
                sublabel.textColor = .grayText
            }
        }
    }

    override func setSublabel() {
        guard let text = self.text else { return }
        if sublabels[text] != nil {
            sublabel.text = sublabels[text]
        }
    }
}
