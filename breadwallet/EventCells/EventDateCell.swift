//
//  EventDateCell.swift
//  breadwallet
//
//  Created by MIP
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit

class EventDateCell: EventDetailRowCell {
    
    var eventID : UInt64 = 0
    
    // MARK: Views
    
    private let eventButton = UIButton(type: .system)
    
    // MARK: - Init
    
    override func addSubviews() {
        super.addSubviews()
        container.addSubview(eventButton)
    }
    
    override func addConstraints() {
        super.addConstraints()
        
        eventButton.constrain([
            eventButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: C.padding[1]),
            eventButton.constraint(.trailing, toView: container),
            eventButton.constraint(.top, toView: container),
            eventButton.constraint(.bottom, toView: container)
            ])
    }
    
    override func setupStyle() {
        super.setupStyle()
        eventButton.titleLabel?.font = .customBody(size: 14.0)
        eventButton.titleLabel?.adjustsFontSizeToFitWidth = true
        eventButton.titleLabel?.minimumScaleFactor = 0.7
        eventButton.titleLabel?.lineBreakMode = .byTruncatingMiddle
        eventButton.titleLabel?.textAlignment = .right
        eventButton.tintColor = .darkText
        
        eventButton.tap = strongify(self) { myself in
            myself.eventButton.tempDisable()
            EventDetailViewController.navigate(to: String(self.eventID), type: EventExplorerType.event)
        }
    }
    
    func set(event: UInt64) {
        self.eventID = event
        eventButton.setTitle(String.init(format: S.EventDetails.event + " #%d", eventID), for: .normal)
    }

}
