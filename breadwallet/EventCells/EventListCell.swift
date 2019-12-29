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
    
    // MARK: Vars
    private var viewModel: BetEventViewModel!
    private var isSyncing : Bool

    // MARK: - Init
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.isSyncing = true
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
    }
    
    private func addConstraints() {
        timestamp.constrain([
            timestamp.topAnchor.constraint(equalTo: contentView.topAnchor, constant: C.padding[1]/2),
            timestamp.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -C.padding[2])])
        headerLabel.constrain([
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: C.padding[1]/2),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[1]),
            headerLabel.trailingAnchor.constraint(lessThanOrEqualTo: timestamp.leadingAnchor)])
        homeTeamLabel.constrain([
            homeTeamLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: C.padding[1]/2),
            homeTeamLabel.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor, constant: C.padding[1])])
        awayTeamLabel.constrain([
            awayTeamLabel.topAnchor.constraint(equalTo: homeTeamLabel.bottomAnchor, constant: C.padding[1]/4),
            awayTeamLabel.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor, constant: C.padding[1])])
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
        headerLabel.numberOfLines = 2
        headerLabel.textAlignment = .left
        headerLabel.lineBreakMode = .byWordWrapping
        homeTeamLabel.textAlignment = .left
        headerLabel.lineBreakMode = .byTruncatingTail
        awayTeamLabel.textAlignment = .left
        awayTeamLabel.lineBreakMode = .byTruncatingTail
        timestamp.setContentHuggingPriority(.required, for: .vertical)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

