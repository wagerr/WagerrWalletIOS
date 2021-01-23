//
//  ParlaySliderCell.swift
//  breadwallet
//
//  Created by MIP
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit
import BRCore

class ParlaySliderCell: EventSliderCellBase {
    
    var viewModel : ParlayBetEntity!
    
    internal override var minBet : Float {
        return W.Parlay.min
    }
    
    internal override var maxBet : Float {
        return W.Parlay.max
    }
    
    internal override var isParlay : Bool {
        return true
    }
    // MARK: Views
    private let totalOddLabel = UILabel(font: UIFont.customBody(size: 24.0))
    private let totalOddTitleLabel = UILabel(font: UIFont.customBody(size: 24.0))

    // MARK: Computed vars
    var totalOdd : UInt32   {
        var ret : Double = 1.0
        for leg in viewModel.legs   {
            let odd = Double(leg.odd) / Double(EventMultipliers.ODDS_MULTIPLIER)
            ret *= odd
        }
    
        return UInt32( ret * Double(EventMultipliers.ODDS_MULTIPLIER) )
    }
    
    var effectiveOdd : UInt32   {
        var effective : Double = 1.0
        for leg in viewModel.legs   {
            let odd = Double(leg.odd) / Double(EventMultipliers.ODDS_MULTIPLIER)
            effective *= ((odd-1)*0.94)+1
        }
        return UInt32( effective * Double(EventMultipliers.ODDS_MULTIPLIER) )
    }
    
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
            totalOddTitleLabel.trailingAnchor.constraint(equalTo: totalOddLabel.leadingAnchor,constant: -C.padding[1]),
            totalOddTitleLabel.topAnchor.constraint(equalTo: totalOddLabel.topAnchor)
        ])

    }
    
    override func setupStyle() {
        super.setupStyle()
        totalOddTitleLabel.text = S.EventDetails.totalOdds
    }
    
    func updateTotalOdds()  {
        totalOddLabel.text = BetEventDatabaseModel.getRawOddTx(odd: (UserDefaults.showNetworkFeesInOdds) ? totalOdd : effectiveOdd)
        self.betChoice = EventBetChoice.init(option: .none, type: .parlay, odd: Double(totalOdd) / Double(EventMultipliers.ODDS_MULTIPLIER), effectiveOdd: Double(effectiveOdd) /  Double(EventMultipliers.ODDS_MULTIPLIER) )
    }
    
}

