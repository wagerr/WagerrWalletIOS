//
//  EventBetOptionCell.swift
//  breadwallet
//
//  Created by MIP
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit

enum EventBetOption {
    case MoneyLine
    case SpreadPoints
    case TotalPoints
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
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        option = .MoneyLine
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
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
        print("tapped")
    }
    
    @objc func actionTappedDraw() {
        print("tapped")
    }
    
    @objc func actionTappedAway() {
        print("tapped")
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
        }
    }
    // MARK: - Views
    
    fileprivate let homeLabel = EventBetLabel(font: UIFont.customBody(size: 24.0))
    fileprivate let awayLabel = EventBetLabel(font: UIFont.customBody(size: 24.0))
    fileprivate let drawLabel = EventBetLabel(font: UIFont.customBody(size: 24.0))

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
