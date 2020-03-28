//
//  EventListCell.swift
//  breadwallet
//
//  Created by MIP on 24/11/2019.
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit

class EventListCell: UITableViewCell {

    // MARK: - Views
    
    private let timestamp = UILabel(font: .customBody(size: 16.0), color: .darkText)
    private var headerLabel = UILabel(font: .customBody(size: 14.0), color: .primaryText)
    private let homeTeamLabel = UILabel(font: .customBody(size: 14.0), color: .primaryText)
    private let awayTeamLabel = UILabel(font: .customBody(size: 14.0), color: .primaryText)
    //private let homeResultLabel = UILabel(font: .customBody(size: 14.0), color: .primaryText)
    //private let awayResultLabel = UILabel(font: .customBody(size: 14.0), color: .primaryText)
    private let oddsLabel = UILabel(font: .customBold(size: 18.0))
    private let separator = UIView(color: .separatorGray)
    private let betsmart = UIButton(type: .system)
    
    // MARK: Vars
    private var viewModel: BetEventViewModel!
    private var isSyncing : Bool
    
    // MARK: - Init
    var didTapBetsmart : (UInt64) -> Void
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.isSyncing = true
        self.didTapBetsmart = { eventID in }
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    func setEvent(_ viewModel: BetEventViewModel, isSyncing: Bool) {
        self.viewModel = viewModel
        self.isSyncing = isSyncing
        
        timestamp.text = viewModel.shortTimestamp
        headerLabel.text = viewModel.eventDescription
        homeTeamLabel.attributedText = viewModel.txAttrHomeTeam
        awayTeamLabel.attributedText = viewModel.txAttrAwayTeam
        oddsLabel.attributedText = viewModel.oddsDescription
        //homeResultLabel.attributedText = viewModel.txAttrHomeResult
        //awayResultLabel.attributedText = viewModel.txAttrAwayResult
    }
    
    // MARK: - Private
    
    private func setupViews() {
        addSubviews()
        addConstraints()
        setupStyle()
    }
    
    private func addSubviews() {
        contentView.addSubview(timestamp)
        contentView.addSubview(headerLabel)
        contentView.addSubview(homeTeamLabel)
        contentView.addSubview(awayTeamLabel)
        contentView.addSubview(oddsLabel)
        //contentView.addSubview(homeResultLabel)
        //contentView.addSubview(awayResultLabel)
        contentView.addSubview(separator)
        contentView.addSubview(betsmart)
    }
    
    private func addConstraints() {
        timestamp.constrain([
            timestamp.topAnchor.constraint(equalTo: contentView.topAnchor, constant: C.padding[1]/2),
            timestamp.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -C.padding[2])])
        betsmart.constrain([
            betsmart.topAnchor.constraint(equalTo: contentView.topAnchor, constant: C.padding[1]/2),
            betsmart.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[1]),
            betsmart.constraint(.width, constant: 48.0),
            betsmart.constraint(.height, constant: 48.0)
        ])
        headerLabel.constrain([
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: C.padding[1]),
            headerLabel.leadingAnchor.constraint(equalTo: betsmart.leadingAnchor, constant: C.padding[5]),
            headerLabel.trailingAnchor.constraint(lessThanOrEqualTo: timestamp.leadingAnchor)])
        homeTeamLabel.constrain([
            homeTeamLabel.topAnchor.constraint(equalTo: betsmart.bottomAnchor, constant: C.padding[1]/2),
            homeTeamLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[2])])
        awayTeamLabel.constrain([
            awayTeamLabel.topAnchor.constraint(equalTo: homeTeamLabel.bottomAnchor, constant: C.padding[1]/4),
            awayTeamLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[2])])
        oddsLabel.constrain([
             oddsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -C.padding[1]/2),
             oddsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -C.padding[2])])
        /*homeResultLabel.constrain([
            homeResultLabel.topAnchor.constraint(equalTo: homeTeamLabel.topAnchor),
            homeResultLabel.trailingAnchor.constraint(equalTo: oddsLabel.leadingAnchor, constant: -C.padding[1])])
        awayResultLabel.constrain([
            awayResultLabel.topAnchor.constraint(equalTo: awayTeamLabel.topAnchor),
            awayResultLabel.trailingAnchor.constraint(equalTo: oddsLabel.leadingAnchor, constant: -C.padding[1])])*/
        separator.constrainBottomCorners(height: 0.5)
    }
    
    private func setupStyle() {
        selectionStyle = .none
        headerLabel.numberOfLines = 1
        headerLabel.textAlignment = .left
        headerLabel.lineBreakMode = .byTruncatingTail
        homeTeamLabel.textAlignment = .left
        awayTeamLabel.textAlignment = .left
        awayTeamLabel.lineBreakMode = .byTruncatingTail
        timestamp.setContentHuggingPriority(.required, for: .vertical)
        
        betsmart.setBackgroundImage(#imageLiteral(resourceName: "betsmartWidget"), for: .normal)
        betsmart.frame = CGRect(x: 6.0, y: 6.0, width: 32.0, height: 32.0) // for iOS 10
        betsmart.widthAnchor.constraint(equalToConstant: 32.0).isActive = true
        betsmart.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
        betsmart.tintColor = .transparentWhite
       
        betsmart.tap = { [weak self] in
            self?.didTapBetsmart((self?.viewModel.eventID)!)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

