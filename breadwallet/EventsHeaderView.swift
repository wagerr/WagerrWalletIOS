//
//  EventsHeaderView.swift
//  breadwallet
//
//  Created by MIP on 24/11/2019.
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit
import BRCore

private let largeFontSize: CGFloat = 28.0
private let smallFontSize: CGFloat = 14.0

class EventsHeaderView : UIView, GradientDrawable, Subscriber, UITextFieldDelegate  {

    // MARK: - Views
    
    private let currencyName = UILabel(font: .customBody(size: 18.0))
    private let exchangeRateLabel = UILabel(font: .customBody(size: 14.0))
    private let balanceLabel = UILabel(font: .customBody(size: 14.0))
    private let primaryBalance: UpdatingLabel
    private let secondaryBalance: UpdatingLabel
    private let conversionSymbol = UIImageView(image: #imageLiteral(resourceName: "conversion"))
    private let currencyTapView = UIView()
    private let syncIndicator = SyncingIndicator(style: .account)
    private let modeLabel = UILabel(font: .customBody(size: 12.0), color: .transparentWhiteText) // debug info
    
    private var regularConstraints: [NSLayoutConstraint] = []
    private var swappedConstraints: [NSLayoutConstraint] = []
    
    private var sportPickerTextField : PaddedPickerTextField!
    private var sports : [ (Int,String) ]
    private var tournamentPickerTextField : PaddedPickerTextField!
    private var tournaments : [Int: [ (Int,String)] ]
    
    // MARK: Properties
    private let currency: CurrencyDef
    private var hasInitialized = false
    private var hasSetup = false
    
    private var isSyncIndicatorVisible: Bool = false {
        didSet {
            UIView.crossfade(balanceLabel, syncIndicator, toRight: isSyncIndicatorVisible, duration: 0.3)
        }
    }
    
    var isWatchOnly: Bool = false {
        didSet {
            /*
            if E.isTestnet || isWatchOnly {
                if E.isTestnet && isWatchOnly {
                    modeLabel.text = "(Testnet - Watch Only)"
                } else if E.isTestnet {
                    modeLabel.text = "(Testnet)"
                } else if isWatchOnly {
                    modeLabel.text = "(Watch Only)"
                }
                modeLabel.isHidden = false
            }
             */
            if E.isScreenshots {
                modeLabel.isHidden = true
            }
        }
    }
    private var exchangeRate: Rate? {
        didSet {
            DispatchQueue.main.async {
                self.setBalances()
            }
        }
    }
    
    private var balance: UInt256 = 0 {
        didSet {
            DispatchQueue.main.async {
                self.setBalances()
            }
        }
    }
    
    private var isBtcSwapped: Bool {
        didSet {
            DispatchQueue.main.async {
                self.setBalances()
            }
        }
    }

    // MARK: -
    
    init(currency: CurrencyDef) {
        self.currency = currency
        self.isBtcSwapped = Store.state.isBtcSwapped
        if let rate = currency.state?.currentRate {
            let placeholderAmount = Amount(amount: 0, currency: currency, rate: rate)
            self.exchangeRate = rate
            self.secondaryBalance = UpdatingLabel(formatter: placeholderAmount.localFormat)
            self.primaryBalance = UpdatingLabel(formatter: placeholderAmount.tokenFormat)
        } else {
            self.secondaryBalance = UpdatingLabel(formatter: NumberFormatter())
            self.primaryBalance = UpdatingLabel(formatter: NumberFormatter())
        }
        let cgrect = CGRect.init(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 300)
        self.sports = [(Int, String)]()
        self.tournaments = [Int: [(Int,String)] ]()
        self.sportPickerTextField = PaddedPickerTextField(frame: cgrect)
        self.tournamentPickerTextField = PaddedPickerTextField(frame: cgrect)
        super.init(frame: CGRect())

        self.sportPickerTextField.delegate = self
        self.tournamentPickerTextField.delegate = self

        setup()
    }
    var didChangeFilters: (([EventFilter]) -> Void)?
    
    // MARK: Private
    fileprivate var filters: [EventSearchFilterType] = [] {
        didSet {
            didChangeFilters?(filters.map { $0.filter })
        }
    }
    
    @discardableResult private func changeFilterType(_ filterType: EventSearchFilterType) -> Bool {
        if let index = filters.index(of: filterType) {
            filters[index] = filterType
        }
        else    {
            filters.append(filterType)
        }
        return true
    }
    
    private func setup() {
        addSubviews()
        addConstraints()
        //addShadow()
        setData()
        addSubscriptions()
    }

    private func setData() {
        currencyName.textColor = .white
        currencyName.textAlignment = .center
        currencyName.text = currency.name
        
        exchangeRateLabel.textColor = .transparentWhiteText
        exchangeRateLabel.textAlignment = .center
        
        balanceLabel.textColor = .transparentWhiteText
        balanceLabel.text = S.Account.balance
        conversionSymbol.tintColor = .whiteTint
        
        primaryBalance.textAlignment = .right
        secondaryBalance.textAlignment = .right
        
        swapLabels()

        modeLabel.isHidden = true
        syncIndicator.isHidden = true
        
        let gr = UITapGestureRecognizer(target: self, action: #selector(currencySwitchTapped))
        currencyTapView.addGestureRecognizer(gr)
        
        let arrowSport = UIImageView(image: #imageLiteral(resourceName: "DownArrow").withRenderingMode(.alwaysTemplate))
        arrowSport.tintColor = .white
        sportPickerTextField.backgroundColor = .gradientStart
        sportPickerTextField.rightView = arrowSport
        sportPickerTextField.rightViewMode = .always
        sportPickerTextField.textColor = .white
        sportPickerTextField.layer.cornerRadius = 5.0
        sportPickerTextField.layer.masksToBounds = true
        //sportPickerTextField.layer.borderWidth = 2.0
        //sportPickerTextField.layer.borderColor = UIColor.white.cgColor
        sportPickerTextField.isUserInteractionEnabled = true
        sportPickerTextField.font = UIFont.customBody(size: 14.0)
        
        let arrowTournament = UIImageView(image: #imageLiteral(resourceName: "DownArrow").withRenderingMode(.alwaysTemplate))
        arrowTournament.tintColor = .white
        tournamentPickerTextField.backgroundColor = .gradientStart
        tournamentPickerTextField.rightView = arrowTournament
        tournamentPickerTextField.rightViewMode = .always
        tournamentPickerTextField.textColor = .white
        tournamentPickerTextField.layer.cornerRadius = 5.0
        tournamentPickerTextField.layer.masksToBounds = true
        //tournamentPickerTextField.layer.borderWidth = 2.0
        //tournamentPickerTextField.layer.borderColor = UIColor.white.cgColor
        tournamentPickerTextField.isUserInteractionEnabled = true
        tournamentPickerTextField.font = UIFont.customBody(size: 14.0)
    }

    private func addSubviews() {
        addSubview(currencyName)
        addSubview(exchangeRateLabel)
        addSubview(sportPickerTextField)
        addSubview(tournamentPickerTextField)
        addSubview(balanceLabel)
        addSubview(primaryBalance)
        addSubview(secondaryBalance)
        addSubview(conversionSymbol)
        addSubview(modeLabel)
        addSubview(syncIndicator)
        addSubview(currencyTapView)
    }

    private func addConstraints() {
        currencyName.constrain([
            currencyName.constraint(.leading, toView: self, constant: C.padding[2]),
            currencyName.constraint(.trailing, toView: self, constant: -C.padding[2]),
            currencyName.constraint(.top, toView: self, constant: E.isIPhoneXOrBetter ? C.padding[5] : C.padding[3])
            ])
        
        exchangeRateLabel.pinTo(viewAbove: currencyName)
        
        sportPickerTextField.constrain([
            sportPickerTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            sportPickerTextField.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: C.padding[3]),
            sportPickerTextField.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(0.35) ),
            sportPickerTextField.heightAnchor.constraint(equalToConstant: CGFloat(30.0) )
            ])
        tournamentPickerTextField.constrain([
            tournamentPickerTextField.leadingAnchor.constraint(equalTo: sportPickerTextField!.trailingAnchor, constant: C.padding[1]/2),
            //tournamentPickerTextField.trailingAnchor.constraint(equalTo: balanceLabel.leadingAnchor),
            tournamentPickerTextField.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: C.padding[3]),
            tournamentPickerTextField.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(0.55)  ),
            tournamentPickerTextField.heightAnchor.constraint(equalToConstant: CGFloat(30.0) )
            ])
        
        balanceLabel.constrain([
            balanceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            balanceLabel.topAnchor.constraint(equalTo: primaryBalance.topAnchor, constant: C.padding[1])
            ])
        
        primaryBalance.constrain([
            primaryBalance.firstBaselineAnchor.constraint(equalTo: exchangeRateLabel.bottomAnchor, constant: C.padding[4])
            ])
        
        secondaryBalance.constrain([
            secondaryBalance.firstBaselineAnchor.constraint(equalTo: exchangeRateLabel.bottomAnchor, constant: C.padding[4]),
            ])
        
        conversionSymbol.constrain([
            conversionSymbol.heightAnchor.constraint(equalToConstant: 12.0),
            conversionSymbol.heightAnchor.constraint(equalTo: conversionSymbol.widthAnchor),
            conversionSymbol.bottomAnchor.constraint(equalTo: primaryBalance.firstBaselineAnchor)
            ])
        
        currencyTapView.constrain([
            currencyTapView.trailingAnchor.constraint(equalTo: balanceLabel.trailingAnchor),
            currencyTapView.topAnchor.constraint(equalTo: primaryBalance.topAnchor, constant: -C.padding[1]),
            currencyTapView.bottomAnchor.constraint(equalTo: primaryBalance.bottomAnchor, constant: C.padding[1]) ])

        regularConstraints = [
            primaryBalance.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            primaryBalance.leadingAnchor.constraint(equalTo: conversionSymbol.trailingAnchor, constant: C.padding[1]),
            conversionSymbol.leadingAnchor.constraint(equalTo: secondaryBalance.trailingAnchor, constant: C.padding[1]),
            currencyTapView.leadingAnchor.constraint(equalTo: secondaryBalance.leadingAnchor),
            //sportPickerTextField.trailingAnchor.constraint(equalTo: secondaryBalance.leadingAnchor, constant: -C.padding[1]),
            //tournamentPickerTextField.trailingAnchor.constraint(equalTo: secondaryBalance.leadingAnchor, constant: -C.padding[1])
        ]

        swappedConstraints = [
            secondaryBalance.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            secondaryBalance.leadingAnchor.constraint(equalTo: conversionSymbol.trailingAnchor, constant: C.padding[1]),
            conversionSymbol.leadingAnchor.constraint(equalTo: primaryBalance.trailingAnchor, constant: C.padding[1]),
            currencyTapView.leadingAnchor.constraint(equalTo: primaryBalance.leadingAnchor),
            //sportPickerTextField.trailingAnchor.constraint(equalTo: primaryBalance.leadingAnchor, constant: -C.padding[1]),
            //tournamentPickerTextField.trailingAnchor.constraint(equalTo: primaryBalance.leadingAnchor, constant: -C.padding[1])
        ]

        NSLayoutConstraint.activate(isBtcSwapped ? self.swappedConstraints : self.regularConstraints)

        modeLabel.constrain([
            modeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            modeLabel.centerYAnchor.constraint(equalTo: balanceLabel.centerYAnchor)
            ])
        
        syncIndicator.constrain([
            syncIndicator.leadingAnchor.constraint(equalTo: balanceLabel.leadingAnchor),
            syncIndicator.topAnchor.constraint(equalTo: balanceLabel.topAnchor),
            syncIndicator.bottomAnchor.constraint(equalTo: balanceLabel.bottomAnchor)
            ])
    }

    private func addShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 8.0
    }

    private func addSubscriptions() {
        Store.lazySubscribe(self,
                            selector: { $0.isBtcSwapped != $1.isBtcSwapped },
                            callback: { self.isBtcSwapped = $0.isBtcSwapped })
        Store.lazySubscribe(self,
                            selector: { $0[self.currency]?.currentRate != $1[self.currency]?.currentRate},
                            callback: {
                                if let rate = $0[self.currency]?.currentRate {
                                    let placeholderAmount = Amount(amount: 0, currency: self.currency, rate: rate)
                                    self.secondaryBalance.formatter = placeholderAmount.localFormat
                                    self.primaryBalance.formatter = placeholderAmount.tokenFormat
                                }
                                self.exchangeRate = $0[self.currency]?.currentRate
        })
        
        Store.lazySubscribe(self,
                            selector: { $0[self.currency]?.maxDigits != $1[self.currency]?.maxDigits},
                            callback: {
                                if let rate = $0[self.currency]?.currentRate {
                                    let placeholderAmount = Amount(amount: 0, currency: self.currency, rate: rate)
                                    self.secondaryBalance.formatter = placeholderAmount.localFormat
                                    self.primaryBalance.formatter = placeholderAmount.tokenFormat
                                    self.setBalances()
                                }
        })
        Store.subscribe(self,
                        selector: { $0[self.currency]?.balance != $1[self.currency]?.balance },
                        callback: { state in
                            if let balance = state[self.currency]?.balance {
                                self.balance = balance
                            } })
        
        Store.subscribe(self, selector: { $0[self.currency]?.syncState != $1[self.currency]?.syncState },
                        callback: { state in
                            guard let syncState = state[self.currency]?.syncState else { return }
                            switch syncState {
                            case .connecting:
                                self.isSyncIndicatorVisible = true
                                self.syncIndicator.text = S.SyncingView.connecting
                            case .syncing:
                                self.isSyncIndicatorVisible = true
                                self.syncIndicator.text = S.SyncingView.syncing
                            case .success:
                                self.isSyncIndicatorVisible = false
                            }
        })
        
        Store.subscribe(self, selector: {
            return $0[self.currency]?.lastBlockTimestamp != $1[self.currency]?.lastBlockTimestamp },
                        callback: { state in
                            if let progress = state[self.currency]?.syncProgress {
                                self.syncIndicator.progress = CGFloat(progress)
                            }
        })
    }

    func updatePickers( sports: [ (Int,String) ], tournaments: [Int: [ (Int, String) ]] )    {
        self.sports = sports
        self.tournaments = tournaments
        let didChangeTournament : (Int) -> Void = { (tournamentID) in
            self.changeFilterType( .tournament(tournamentID) )
            self.tournamentPickerTextField.resignFirstResponder()
        }
        sportPickerTextField.loadDropdownData(data: sports, didChangePicker: { (sportID) in
            self.tournamentPickerTextField.loadDropdownData(data: tournaments[sportID] ?? tournaments[0]!, didChangePicker: didChangeTournament)
            self.changeFilterType( .sport(sportID) )
            self.changeFilterType( .tournament(-1) )
            self.sportPickerTextField.resignFirstResponder()
        } )
        tournamentPickerTextField.loadDropdownData(data: tournaments[sportPickerTextField.getSelectedIndex()] ?? tournaments[0]!, didChangePicker: didChangeTournament )
    }

    func setBalances() {
        guard let rate = exchangeRate else { return }
        
        exchangeRateLabel.text = String(format: S.AccountHeader.exchangeRate, rate.localString, currency.code)
        
        let amount = Amount(amount: balance, currency: currency, rate: rate)
        
        if !hasInitialized {
            primaryBalance.setValue(amount.tokenValue)
            secondaryBalance.setValue(amount.fiatValue)
            swapLabels()
            hasInitialized = true
        } else {
            if primaryBalance.isHidden {
                primaryBalance.isHidden = false
            }

            if secondaryBalance.isHidden {
                secondaryBalance.isHidden = false
            }
            
            primaryBalance.setValueAnimated(amount.tokenValue, completion: { [weak self] in
                self?.swapLabels()
            })
            secondaryBalance.setValueAnimated(amount.fiatValue, completion: { [weak self] in
                self?.swapLabels()
            })
        }
    }
    
    private func swapLabels() {
        NSLayoutConstraint.deactivate(isBtcSwapped ? regularConstraints : swappedConstraints)
        NSLayoutConstraint.activate(isBtcSwapped ? swappedConstraints : regularConstraints)
        if isBtcSwapped {
            primaryBalance.makeSecondary()
            secondaryBalance.makePrimary()
        } else {
            primaryBalance.makePrimary()
            secondaryBalance.makeSecondary()
        }
    }

    override func draw(_ rect: CGRect) {
        drawGradient(start: currency.colors.0, end: currency.colors.1, rect)
    }

    @objc private func currencySwitchTapped() {
        layoutIfNeeded()
        UIView.spring(0.7, animations: {
            self.primaryBalance.toggle()
            self.secondaryBalance.toggle()
            NSLayoutConstraint.deactivate(!self.isBtcSwapped ? self.regularConstraints : self.swappedConstraints)
            NSLayoutConstraint.activate(!self.isBtcSwapped ? self.swappedConstraints : self.regularConstraints)
            self.layoutIfNeeded()
        }) { _ in }

        Store.perform(action: CurrencyChange.toggle())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - textfield delegate
 /*   func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return false
    }
 */
}

// MARK: -

private extension UILabel {
    func makePrimary() {
        font = UIFont.customBold(size: largeFontSize)
        textColor = .white
        reset()
    }
    
    func makeSecondary() {
        font = UIFont.customBody(size: largeFontSize)
        textColor = .transparentWhiteText
        shrink()
    }
    
    func shrink() {
        transform = .identity // must reset the view's transform before we calculate the next transform
        let scaleFactor: CGFloat = smallFontSize/largeFontSize
        let deltaX = frame.width * (1-scaleFactor)
        let deltaY = frame.height * (1-scaleFactor)
        let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        transform = scale.translatedBy(x: deltaX, y: deltaY/2.0)
    }
    
    func reset() {
        transform = .identity
    }
    
    func toggle() {
        if transform.isIdentity {
            makeSecondary()
        } else {
            makePrimary()
        }
    }
}

