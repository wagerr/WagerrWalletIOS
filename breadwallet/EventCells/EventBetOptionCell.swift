//
//  EventBetOptionCell.swift
//  breadwallet
//
//  Created by MIP
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit
import BRCore

enum EventBetOption {
    case MoneyLine
    case SpreadPoints
    case TotalPoints
    case none
}

enum EventBetType   {
    case home
    case away
    case draw
    case over
    case under
    case none
    case parlay
}

struct EventBetChoice {
    let option : EventBetOption
    let type : EventBetType
    let odd : Double
    let effectiveOdd : Double
    
    init(option: EventBetOption, type: EventBetType, odd: Double, effectiveOdd: Double) {
        self.option = option
        self.type = type
        self.odd = odd
        self.effectiveOdd = effectiveOdd
    }
    
    func getOutcome() -> BetOutcome {
        switch option {
        case .MoneyLine:
            switch type {
                case .home:
                    return .MONEY_LINE_HOME_WIN
                case .away:
                    return .MONEY_LINE_AWAY_WIN
                case .draw:
                    return .MONEY_LINE_DRAW
                default:
                    return .UNKNOWN
            }
        case .SpreadPoints:
            switch type {
                case .home:
                    return .SPREADS_HOME
                case .away:
                    return .SPREADS_AWAY
                default:
                    return .UNKNOWN
            }
        case .TotalPoints:
            switch type {
            case .over:
                return .TOTAL_OVER
            case .under:
                return .TOTAL_UNDER
            default:
                return .UNKNOWN
            }
        case .none:
            return .UNKNOWN
        }
    }
    
    func potentialReward(stake: Int, event: BetEventDatabaseModel?) -> (cryptoAmount: String, fiatAmount: String )   {
        let decimalOdd = getEffectiveOdd(event: event)
        let winningAmount: Double = Double(stake) * (decimalOdd - 1)
        var cryptoAmount: Double = Double(stake) + winningAmount
        cryptoAmount = cryptoAmount.truncate(places: 2)
        let currency = Currencies.btc
        let rate = currency.state?.currentRate
        let amount = Amount(amount: UInt256(UInt64(cryptoAmount*Double(C.satoshis))), currency: currency, rate: rate)
        return (String.init(format: "%.2f %@", cryptoAmount, currency.code), amount.fiatDescription)
    }
    
    func getEffectiveOdd( event: BetEventDatabaseModel? ) -> Double {
        var ret : Double
        switch type {
        case .home:
            ret = (option == EventBetOption.MoneyLine) ? Double(event!.homeOdds) : Double(event!.spreadHomeOdds)
        case .away:
            ret = (option == EventBetOption.MoneyLine) ? Double(event!.awayOdds) : Double(event!.spreadAwayOdds)
        case .draw:
            ret = Double(event!.drawOdds)
        case .over:
            ret = Double(event!.overOdds)
        case .under:
            ret = Double(event!.underOdds)
        case .none:
            ret = 0
        case .parlay:
            return effectiveOdd
        }
        ret = ret / Double(EventMultipliers.ODDS_MULTIPLIER)
        ret = ((ret-1)*0.94)+1
        return ret
    }
    
    func AmericanToDecimal( odd: Float ) -> Float   {
        if odd > 0  {
            return  round( ((odd / 100) + 1.0)*100 )/100
        }
        else    {
            return round( ((100 / -odd) + 1.0)*100 )/100
        }
    }
}

class EventBetOptionSpreadsCell : EventBetOptionCell    {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        option = .SpreadPoints
        drawLabel.isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class EventBetOptionTotalsCell : EventBetOptionCell    {
    fileprivate let overHeaderLabel = UILabel(font: UIFont.customBody(size: 12.0))
    fileprivate let underHeaderLabel = UILabel(font: UIFont.customBody(size: 12.0))

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        option = .TotalPoints
        drawLabel.isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc override func actionTappedHome() {
        guard home != "N/A" else { return }
        let choice = EventBetChoice.init(option: self.option, type: .over, odd: Double(homeLabel.text!)!,effectiveOdd: 0)
        self.cellDelegate?.didTapBetOption ( choice: choice, isSelected: homeLabel.toggleLabel() )
        print("tapped")
    }
    
    @objc override func actionTappedAway() {
        guard away != "N/A" else { return }
        let choice = EventBetChoice.init(option: self.option, type: .under, odd: Double(awayLabel.text!)!,effectiveOdd: 0)
        self.cellDelegate?.didTapBetOption ( choice: choice, isSelected: awayLabel.toggleLabel() )
        print("tapped")
    }
    
    override func addSubviews() {
        super.addSubviews()
        container.addSubview(overHeaderLabel)
        container.addSubview(underHeaderLabel)
    }
    
    override func addConstraints() {
        super.addConstraints()
        
        overHeaderLabel.constrain([
            overHeaderLabel.leadingAnchor.constraint(equalTo: homeLabel.leadingAnchor),
            overHeaderLabel.bottomAnchor.constraint(equalTo: homeLabel.topAnchor, constant: -C.padding[1])
        ])
        underHeaderLabel.constrain([
            underHeaderLabel.leadingAnchor.constraint(equalTo: awayLabel.leadingAnchor),
            underHeaderLabel.bottomAnchor.constraint(equalTo: awayLabel.topAnchor, constant: -C.padding[1])
            ])
    }
    
    override func restoreLabelsSize(choice: EventBetChoice)    {
        if choice.option == self.option {
            if choice.type != .over { homeLabel.font = homeLabel.font.withSize(W.FontSize.normalSize) }
            if choice.type != .under { awayLabel.font = awayLabel.font.withSize(W.FontSize.normalSize) }
        }
        else    {
            homeLabel.font = homeLabel.font.withSize(W.FontSize.normalSize)
            awayLabel.font = awayLabel.font.withSize(W.FontSize.normalSize)
        }
    }
    
    override func setupStyle() {
        super.setupStyle()
        overHeaderLabel.textColor = .secondaryGrayText
        overHeaderLabel.textAlignment = .left
        underHeaderLabel.textColor = .secondaryGrayText
        underHeaderLabel.textAlignment = .left
        overHeaderLabel.text = S.EventDetails.overOdds
        underHeaderLabel.text = S.EventDetails.underOdds
    }
}

class EventBetOptionCell: EventDetailRowCell {

    var cellDelegate: EventBetOptionDelegate?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        option = .MoneyLine
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        let balanceAmount = (Currencies.btc.state?.balance!.asUInt64)!/C.satoshis
        if Float(balanceAmount) >= W.BetAmount.min  {
            addGestures()
        }
    }
    
    // MARK: - Accessors
    public var option : EventBetOption

    public var home: String {
        get {
            return homeLabel.text ?? ""
        }
        set {
            homeLabel.text = newValue
        }
    }

    public var away: String {
        get {
            return awayLabel.text ?? ""
        }
        set {
            awayLabel.text = newValue
        }
    }
    
    public var draw: String {
        get {
            return drawLabel.text ?? ""
        }
        set {
            drawLabel.text = newValue
            drawLabel.isHidden = ( newValue == "N/A" )
        }
    }
    
    func addGestures()  {
        let tapActionHome = UITapGestureRecognizer(target: self, action:#selector(self.actionTappedHome))
        homeLabel.isUserInteractionEnabled = true
        homeLabel.addGestureRecognizer(tapActionHome)

        let tapActionDraw = UITapGestureRecognizer(target: self, action:#selector(self.actionTappedDraw))
        drawLabel.isUserInteractionEnabled = true
        drawLabel.addGestureRecognizer(tapActionDraw)

        let tapActionAway = UITapGestureRecognizer(target: self, action:#selector(self.actionTappedAway))
        awayLabel.isUserInteractionEnabled = true
        awayLabel.addGestureRecognizer(tapActionAway)
    }
    
    private func setupViews() {
        addSubviews()
        addConstraints()
        setupStyle()
    }
    
    // MARK: - Tap actions
    @objc func actionTappedHome() {
        guard home != "N/A" else { return }
        let choice = EventBetChoice.init(option: self.option, type: .home, odd: Double(homeLabel.text!)!,effectiveOdd: 0)
        self.cellDelegate?.didTapBetOption ( choice: choice, isSelected: homeLabel.toggleLabel() )
        print("tapped")
    }
    
    @objc func actionTappedDraw() {
        guard draw != "N/A" else { return }
        let choice = EventBetChoice.init(option: self.option, type: .draw, odd: Double(drawLabel.text!)!,effectiveOdd: 0)
        self.cellDelegate?.didTapBetOption ( choice: choice, isSelected: drawLabel.toggleLabel() )
        print("tapped")
    }
    
    @objc func actionTappedAway() {
        guard away != "N/A" else { return }
        let choice = EventBetChoice.init(option: self.option, type: .away, odd: Double(awayLabel.text!)!,effectiveOdd: 0)
        self.cellDelegate?.didTapBetOption ( choice: choice, isSelected: awayLabel.toggleLabel() )
    }
    
    func restoreLabelsSize(choice: EventBetChoice)    {
        if choice.option == self.option {
            if choice.type != .home { homeLabel.font = homeLabel.font.withSize(W.FontSize.normalSize) }
            if choice.type != .draw { drawLabel.font = drawLabel.font.withSize(W.FontSize.normalSize) }
            if choice.type != .away { awayLabel.font = awayLabel.font.withSize(W.FontSize.normalSize) }
        }
        else    {
            homeLabel.font = homeLabel.font.withSize(W.FontSize.normalSize)
            drawLabel.font = drawLabel.font.withSize(W.FontSize.normalSize)
            awayLabel.font = awayLabel.font.withSize(W.FontSize.normalSize)
        }
    }
    
    // MARK: - Views
    fileprivate let homeLabel = EventBetLabel(font: UIFont.customBody(size: W.FontSize.normalSize))
    fileprivate let awayLabel = EventBetLabel(font: UIFont.customBody(size: W.FontSize.normalSize))
    fileprivate let drawLabel = EventBetLabel(font: UIFont.customBody(size: W.FontSize.normalSize))

    // MARK: - Init
    
    override func addSubviews() {
        super.addSubviews()
        container.addSubview(homeLabel)
        container.addSubview(awayLabel)
        container.addSubview(drawLabel)
    }
    
    override func addConstraints() {
        rowHeight = CGFloat(49.0)
        super.addContraintMain()
        
        titleLabel.constrain([
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.constraint(toTop: container, constant: C.padding[1])
        ])
        
        let vPadding = C.padding[1]
        
        drawLabel.constrain([
            drawLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            drawLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: vPadding)
        ])
        homeLabel.constrain([
            homeLabel.trailingAnchor.constraint(equalTo: drawLabel.leadingAnchor, constant: -C.padding[2]),
            homeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: vPadding)
            ])
        awayLabel.constrain([
            awayLabel.leadingAnchor.constraint(equalTo: drawLabel.trailingAnchor, constant: C.padding[2]),
            awayLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: vPadding)
        ])
    }
    
    override func setupStyle() {
        super.setupStyle()
        
        homeLabel.textColor = .colorHomeText
        homeLabel.backgroundColor = .colorHome
        homeLabel.textAlignment = .center
        homeLabel.sizeToFit()
        
        awayLabel.textColor = .colorAwayText
        awayLabel.backgroundColor = .colorAway
        awayLabel.textAlignment = .center
        awayLabel.sizeToFit()
        
        drawLabel.textColor = .white
        drawLabel.backgroundColor = .colorDraw
        drawLabel.textAlignment = .center
        drawLabel.sizeToFit()

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
