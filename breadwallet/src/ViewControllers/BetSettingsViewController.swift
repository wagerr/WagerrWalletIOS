//
//  NodeSelectorViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-08-03.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit
import BRCore

class BetSettingsViewController : UIViewController, UITextFieldDelegate {

    var delegate : BetSettingsDelegate? = nil
    let titleLabel = UILabel(font: .customBold(size: 24.0), color: .darkText)
    //private let checkIncludeFee = UIButton(type: .system)
    private let checkIncludeFee = UISwitch(frame: CGRect(x: 163, y: 150, width: 0, height: 0))
    private let labelIncludeFee = UILabel(font: UIFont.customBody(size: 14.0), color: .primaryText)
    private let separator1 = UIView(color: .secondaryShadow)
    private let checkUseAmerican = UISwitch(frame: CGRect(x: 163, y: 150, width: 0, height: 0))
    private let labelUseAmerican = UILabel(font: UIFont.customBody(size: 14.0), color: .primaryText)
    private let separator2 = UIView(color: .secondaryShadow)
    private let labelMinBet = UILabel(font: UIFont.customBody(size: 14.0), color: .primaryText)
    private let textMinBet = UITextField(frame: CGRect(x: 10.0, y: 10.0, width: 250.0, height: 35.0))
    private let separator3 = UIView(color: .secondaryShadow)
    private let labelCurrency = UILabel(font: UIFont.customBody(size: 24.0), color: .primaryText)
    
    // MARK: - Accessors
    public var defaultBet: String {
        get {
            return textMinBet.text ?? ""
        }
        set {
            textMinBet.text = newValue
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        setInitialData()
    }

    private func addSubviews() {
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "< Back", style: UIBarButtonItemStyle.bordered, target: self, action: #selector(self.back(sender:)))
        newBackButton.tintColor = .primaryText
        self.navigationItem.leftBarButtonItem = newBackButton
        
        view.addSubview(titleLabel)
        view.addSubview(checkIncludeFee)
        view.addSubview(labelIncludeFee)
        view.addSubview(separator1)
        view.addSubview(checkUseAmerican)
        view.addSubview(labelUseAmerican)
        view.addSubview(separator2)
        view.addSubview(labelMinBet)
        view.addSubview(textMinBet)
        view.addSubview(labelCurrency)
        view.addSubview(separator3)
    }

    @objc func back(sender: UIBarButtonItem) {
        delegate?.didTapBetSettingsBack()
        self.navigationController?.popViewController(animated: true)
    }
    
    private func addConstraints() {
        var padding = C.padding[2]
        if delegate != nil {
            padding = C.padding[10]
        }
        titleLabel.constrain([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2])
            ])
        
        checkIncludeFee.constrain([
            checkIncludeFee.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: C.padding[2]),
            checkIncludeFee.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
        ])
        
        separator1.constrain([
            separator1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            separator1.topAnchor.constraint(equalTo: checkIncludeFee.bottomAnchor, constant: C.padding[1]),
            separator1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
            separator1.heightAnchor.constraint(equalToConstant: 1.0) ])
        
        labelIncludeFee.constrain([
            labelIncludeFee.topAnchor.constraint(equalTo: checkIncludeFee.topAnchor, constant: C.padding[1]/2 ),
            labelIncludeFee.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[4]),
            labelIncludeFee.trailingAnchor.constraint(equalTo: checkIncludeFee.leadingAnchor, constant: -C.padding[2]),
        ])
        
        checkUseAmerican.constrain([
            checkUseAmerican.topAnchor.constraint(equalTo: separator1.bottomAnchor, constant: C.padding[2]),
            checkUseAmerican.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
        ])
        
        separator2.constrain([
            separator2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            separator2.topAnchor.constraint(equalTo: checkUseAmerican.bottomAnchor, constant: C.padding[1]),
            separator2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
            separator2.heightAnchor.constraint(equalToConstant: 1.0) ])
            
        labelUseAmerican.constrain([
            labelUseAmerican.topAnchor.constraint(equalTo: checkUseAmerican.topAnchor, constant: C.padding[1]/2 ),
            labelUseAmerican.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[4]),
            labelUseAmerican.trailingAnchor.constraint(equalTo: checkUseAmerican.leadingAnchor, constant: -C.padding[2]),
        ])

        labelCurrency.constrain([
            labelCurrency.topAnchor.constraint(equalTo: separator2.bottomAnchor, constant: C.padding[1]),
            labelCurrency.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
        ])
        
        textMinBet.constrain([
            textMinBet.topAnchor.constraint(equalTo: separator2.bottomAnchor, constant: C.padding[1]),
            textMinBet.trailingAnchor.constraint(equalTo: labelCurrency.leadingAnchor, constant: -C.padding[1]/2),
        ])
        
        separator3.constrain([
            separator3.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            separator3.topAnchor.constraint(equalTo: textMinBet.bottomAnchor, constant: C.padding[1]),
            separator3.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
            separator3.heightAnchor.constraint(equalToConstant: 1.0) ])
            
        labelMinBet.constrain([
            labelMinBet.topAnchor.constraint(equalTo: textMinBet.topAnchor, constant: C.padding[1]/2 ),
            labelMinBet.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[4]),
            labelMinBet.trailingAnchor.constraint(equalTo: textMinBet.leadingAnchor, constant: -C.padding[2]),
        ])

    }

    private func setInitialData() {
        view.backgroundColor = .whiteBackground
        titleLabel.text = S.BetSettings.headerMessage
        titleLabel.textAlignment = .right
        labelIncludeFee.text = S.BetSettings.useFeeCheck
        labelIncludeFee.lineBreakMode = .byWordWrapping
        labelIncludeFee.numberOfLines = 2
        checkIncludeFee.tap = strongify(self) { myself in
            UserDefaults.showNetworkFeesInOdds = self.checkIncludeFee.isOn
        }
        
        self.checkIncludeFee.isOn = UserDefaults.showNetworkFeesInOdds
        
        labelUseAmerican.text = S.BetSettings.useAmerican
        labelUseAmerican.lineBreakMode = .byWordWrapping
        labelUseAmerican.numberOfLines = 2
        checkUseAmerican.tap = strongify(self) { myself in
            UserDefaults.showAmericanNotationInOdds = self.checkUseAmerican.isOn
        }
        
        self.checkUseAmerican.isOn = UserDefaults.showAmericanNotationInOdds
        
        labelMinBet.text = S.BetSettings.defaultBetAmount
        labelMinBet.lineBreakMode = .byWordWrapping
        labelMinBet.numberOfLines = 2
        
        textMinBet.textColor = .primaryText
        let defBet =  UserDefaults.defaultBetAmount
        self.defaultBet = String.init( String(defBet))
        textMinBet.delegate = self
        textMinBet.returnKeyType = UIReturnKeyType.done
        textMinBet.keyboardType = UIKeyboardType.numberPad
        textMinBet.font = UIFont.customBody(size: 24.0)
        addDoneButtonOnKeyboard()
        
        var bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0.0, y: textMinBet.frame.height - 1, width: textMinBet.frame.width, height: 1.0)
        bottomLine.backgroundColor = UIColor.lightGray.cgColor
        textMinBet.borderStyle = UITextField.BorderStyle.none
        textMinBet.layer.addSublayer(bottomLine)
        
        labelCurrency.text = Currencies.btc.code
    }

    func addDoneButtonOnKeyboard()
    {
        var doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = UIBarStyle.blackTranslucent

        var flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        var done: UIBarButtonItem = UIBarButtonItem(title: S.RecoverWallet.done, style: UIBarButtonItemStyle.done, target: self, action: #selector(self.doneButtonAction))
        done.tintColor = .white

        var items = NSMutableArray()
        items.add(flexSpace)
        items.add(done)

        doneToolbar.items = items as! [UIBarButtonItem]
        doneToolbar.sizeToFit()

        self.textMinBet.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction()
    {
        self.textMinBet.resignFirstResponder()
    }
    
    // amount text field delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        UserDefaults.defaultBetAmount = Int(defaultBet) ?? Int(W.BetAmount.min)
        if UserDefaults.defaultBetAmount < Int(W.BetAmount.min) {
            UserDefaults.defaultBetAmount = Int(W.BetAmount.min)
            defaultBet = String.init( UserDefaults.defaultBetAmount )
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

