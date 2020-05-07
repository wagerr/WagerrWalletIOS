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
    
    var availableCurrencies : [String]
    
    override init(currency: CurrencyDef, isPinPadExpandedAtLaunch: Bool, isRequesting: Bool = false) {
        self.availableCurrencies = [ "BTC" ]
        super.init(currency: currency, isPinPadExpandedAtLaunch: isPinPadExpandedAtLaunch, isRequesting: isRequesting)
        self.currencyToggle = ShadowButton(title: availableCurrencies[0], type: .tertiary)
        self.canEditFee = false
    }
    
    override internal func toggleCurrency() {
        guard let selrate = selectedRate else { return }
        var index = (availableCurrencies.index(of: selectedRate!.code) ?? 0) + 1
        if index == availableCurrencies.count {
            index = 0
        }
        let selectedCurrency = availableCurrencies[index]
        guard let newRate = Store.state[currency]!.rates.first( where: { $0.code == selectedCurrency }) else { return }
        self.selectedRate = newRate
        currencyToggle.title = selectedRate!.code
        placeholder.text = String.init(format: S.Instaswap.amountLabel, selectedRate!.code)
        didUpdateAmount!(amount, selectedRate!.code)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setInitialData() {
        super.setInitialData()
        guard let BTCRate = Store.state[currency]!.rates.first( where: { $0.code == availableCurrencies[0] }) else { return }
        selectedRate = BTCRate
        placeholder.text = String.init(format: S.Instaswap.amountLabel, selectedRate!.code)
    }
    
    override internal func updateCurrencyToggleTitle() {
        guard let currencyState = currency.state else { return }
        if let rate = selectedRate {
            self.currencyToggle.title = "\(rate.code)"
        } else {
            currencyToggle.title = currency.unitName(forDecimals: currencyState.maxDigits)
        }
    }
}
