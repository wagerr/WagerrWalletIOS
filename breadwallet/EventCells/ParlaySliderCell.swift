//
//  ParlaySliderCell.swift
//  breadwallet
//
//  Created by MIP
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit
import BRCore

class ParlaySliderCell: EventSliderCell {
    
    // MARK: Views
    private let totalOddLabel = UILabel(font: UIFont.customBody(size: 24.0))
    private let totalOddTitleLabel = UILabel(font: UIFont.customBody(size: 24.0))

    // MARK: - Init
    
    override func addSubviews() {
        super.addSubviews()
        container.addSubview(totalOddLabel)
        container.addSubview(totalOddTitleLabel)
    }
    
    override func addConstraints() {
        rowHeight = CGFloat(120.0)
        super.addConstraints()
    
        totalOddLabel.constrain([
            totalOddLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            totalOddLabel.constraint(toTop: container, constant: C.padding[3])
        ])
        
        totalOddTitleLabel.constrain([
            totalOddTitleLabel.trailingAnchor.constraint(equalTo: totalOddLabel.leadingAnchor,constant: C.padding[1]),
            totalOddTitleLabel.topAnchor.constraint(equalTo: totalOddLabel.topAnchor)
        ])

    }
    
    override func setupStyle() {
        super.setupStyle()
        
        totalOddTitleLabel.text = S.EventDetails.totalOdds
    }
    
}

