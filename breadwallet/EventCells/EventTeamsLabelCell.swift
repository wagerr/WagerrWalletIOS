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
    
    // MARK: - Init
    
    override func addSubviews() {
        super.addSubviews()
        container.addSubview(homeHeaderLabel)
        container.addSubview(homeLabel)
        container.addSubview(awayHeaderLabel)
        container.addSubview(awayLabel)
    }
    
    override func addConstraints() {
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
            homeLabel.topAnchor.constraint(equalTo: homeHeaderLabel.bottomAnchor, constant: C.padding[1]/2)
            ])
        awayLabel.constrain([
            awayLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            awayLabel.topAnchor.constraint(equalTo: awayHeaderLabel.bottomAnchor, constant: C.padding[1]/2)
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
        awayLabel.textColor = .colorAway
        awayLabel.textAlignment = .right
    }
}
