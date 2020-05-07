//
//  EventTeamsLabelCell.swift
//  breadwallet
//
//  Created by MIP
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit

class EventTeamsLabelCell: EventDetailRowCell {
    
    // MARK: - Accessors
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
    
    // MARK: - Views
    
    fileprivate let homeHeaderLabel = UILabel(font: UIFont.customBody(size: 12.0))
    fileprivate let homeLabel = UILabel(font: UIFont.customBody(size: 16.0))
    fileprivate let awayHeaderLabel = UILabel(font: UIFont.customBody(size: 12.0))
    fileprivate let awayLabel = UILabel(font: UIFont.customBody(size: 16.0))
    private let betsmartHome = UIButton(type: .system)
    private let betsmartAway = UIButton(type: .system)
    
    var didTapBetsmart : (String) -> Void = {_ in}
    
    // MARK: - Init
    
    override func addSubviews() {
        super.addSubviews()
        container.addSubview(homeHeaderLabel)
        container.addSubview(homeLabel)
        container.addSubview(awayHeaderLabel)
        container.addSubview(awayLabel)
        container.addSubview(betsmartHome)
        container.addSubview(betsmartAway)
    }
    
    override func addConstraints() {
        rowHeight = CGFloat(70.0)
        super.addConstraints()
        
        homeHeaderLabel.constrain([
            homeHeaderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            homeHeaderLabel.constraint(.top, toView: container),
            //homeHeaderLabel.constraint(.bottom, toView: container)
            ])
        awayHeaderLabel.constrain([
            awayHeaderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            awayHeaderLabel.constraint(.top, toView: container),
            //homeHeaderLabel.constraint(.bottom, toView: container)
        ])
        homeLabel.constrain([
            homeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            homeLabel.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor, multiplier: 0.5, constant: -C.padding[1]/2),
            homeLabel.topAnchor.constraint(equalTo: homeHeaderLabel.bottomAnchor, constant: C.padding[1]/2)
            ])
        awayLabel.constrain([
            awayLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            awayLabel.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor, multiplier: 0.5, constant: -C.padding[1]/2),
            awayLabel.topAnchor.constraint(equalTo: awayHeaderLabel.bottomAnchor, constant: C.padding[1]/2)
        ])
        
        betsmartHome.constrain([
            betsmartHome.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            betsmartHome.topAnchor.constraint(equalTo: homeLabel.bottomAnchor, constant: C.padding[1]/2)
            ])
        betsmartAway.constrain([
            betsmartAway.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            betsmartAway.topAnchor.constraint(equalTo: awayLabel.bottomAnchor, constant: C.padding[1]/2)
        ])
    }
    
    override func setupStyle() {
        super.setupStyle()
        homeHeaderLabel.textColor = .secondaryGrayText
        homeHeaderLabel.textAlignment = .left
        awayHeaderLabel.textColor = .secondaryGrayText
        awayHeaderLabel.textAlignment = .right
        homeHeaderLabel.text = S.EventDetails.homeTeam
        awayHeaderLabel.text = S.EventDetails.awayTeam
        
        homeLabel.textColor = .colorHome
        homeLabel.textAlignment = .left
        homeLabel.lineBreakMode = .byWordWrapping
        homeLabel.numberOfLines = 2
        awayLabel.textColor = .colorAway
        awayLabel.textAlignment = .right
        awayLabel.lineBreakMode = .byWordWrapping
        awayLabel.numberOfLines = 2
        
        betsmartHome.setBackgroundImage(#imageLiteral(resourceName: "betsmartWidget"), for: .normal)
         betsmartHome.frame = CGRect(x: 6.0, y: 6.0, width: 32.0, height: 32.0) // for iOS 10
         betsmartHome.widthAnchor.constraint(equalToConstant: 32.0).isActive = true
         betsmartHome.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
         betsmartHome.tintColor = .transparentWhite
        
         betsmartHome.tap = { [weak self] in
             self?.didTapBetsmart((self?.home)!)
         }
        
        betsmartAway.setBackgroundImage(#imageLiteral(resourceName: "betsmartWidget"), for: .normal)
         betsmartAway.frame = CGRect(x: 6.0, y: 6.0, width: 32.0, height: 32.0) // for iOS 10
         betsmartAway.widthAnchor.constraint(equalToConstant: 32.0).isActive = true
         betsmartAway.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
         betsmartAway.tintColor = .transparentWhite
        
         betsmartAway.tap = { [weak self] in
             self?.didTapBetsmart((self?.away)!)
         }
    }
}
