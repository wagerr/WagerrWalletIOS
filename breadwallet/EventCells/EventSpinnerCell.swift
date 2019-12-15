//
//  EventSpinnerCell.swift
//  breadwallet
//
//  Created by MIP
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit

class EventSpinnerCell: EventDetailRowCell {
    
    var eventID : UInt64 = 0
    
    // MARK: Views
    
    private let amountLabel = UILabel(font: UIFont.customBody(size: 24.0))
    private let rewardLabel = UILabel(font: UIFont.customBody(size: 16.0))
    private let betSlider = UISlider()
    private let doBetButton = UIButton(type: .system)
    private let doCancelButton = UIButton(type: .system)
    
    // MARK: - Init
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        //betSlider.frame = container.frame
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubviews()
        addConstraints()
        setupStyle()
    }
    
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
