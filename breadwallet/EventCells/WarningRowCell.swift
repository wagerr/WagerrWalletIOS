//
//  WarningRowCell.swift
//  breadwallet
//
//  Created by MIP
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit

class WarningRowCell : EventDetailRowCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    internal override func setupStyle() {
        titleLabel.textColor = .systemRed
        titleLabel.font = UIFont.customBold(size: 18.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
