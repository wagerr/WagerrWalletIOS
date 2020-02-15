//
//  AmountViewController.swift
//  Wagerr Pro
//
//  Created by Adrian Corscadden on 2017-05-19.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit
import BRCore

private let currencyHeight: CGFloat = 100.0
private let feeHeight: CGFloat = 150.0

class SwapAmountViewController : AmountViewController {
    
    override init(currency: CurrencyDef, isPinPadExpandedAtLaunch: Bool, isRequesting: Bool = false) {
        super.init(currency: currency, isPinPadExpandedAtLaunch: isPinPadExpandedAtLaunch, isRequesting: isRequesting)
        self.currencyToggle = ShadowButton(title: "BTC", type: .tertiary)
    }

    override internal func toggleCurrency() {
        return // do nothing here
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
