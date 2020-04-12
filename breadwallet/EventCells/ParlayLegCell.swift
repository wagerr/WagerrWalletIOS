//
//  ParlayLegCell.swift
//  breadwallet
//
//  Created by MIP on 09/04/2020.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit

class ParlayLegCell: UITableViewCell {

    var cellDelegate: ParlayBetLegDelegate?
    var legIndex : Int?
    
    // MARK: - Views
    internal let container = UIView()
    private let timestamp = UILabel(font: .customBody(size: 16.0), color: .darkText)
    private var headerLabel = UILabel(font: .customBody(size: 14.0), color: .primaryText)
    private let homeTeamLabel = UILabel(font: .customBody(size: 14.0), color: .primaryText)
    private let awayTeamLabel = UILabel(font: .customBody(size: 14.0), color: .primaryText)
    //private let homeResultLabel = UILabel(font: .customBody(size: 14.0), color: .primaryText)
    //private let awayResultLabel = UILabel(font: .customBody(size: 14.0), color: .primaryText)
    private let outcomeLabel = UILabel(font: .customBold(size: 14.0))
    private let oddsLabel = EventBetLabel(font: .customBold(size: 18.0))
    private let deleteButton = UIImageView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
    private let separator = UIView(color: .separatorGray)
    //private let betsmart = UIButton(type: .system)
    
    // MARK: Vars
    private var viewModel: ParlayLegEntity!
    
    // MARK: - Init
    //var didTapBetsmart : (UInt64) -> Void
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        //self.didTapBetsmart = { eventID in }
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    func setParlayLeg(_ viewModel: ParlayLegEntity) {
        self.viewModel = viewModel
        
        timestamp.text = viewModel.event.shortTimestamp
        headerLabel.text = viewModel.event.eventDescription
        homeTeamLabel.attributedText = viewModel.event.txAttrHomeTeam
        awayTeamLabel.attributedText = viewModel.event.txAttrAwayTeam
        outcomeLabel.text = viewModel.outcome.description
        oddsLabel.text = BetEventViewModel.getOddTx(odd: viewModel.odd)
        oddsLabel.textColor = .white
        oddsLabel.backgroundColor = viewModel.getOddColor()
    }
    
    // MARK: - Private
    
    private func setupViews() {
        addSubviews()
        addConstraints()
        setupStyle()
    }
    
    private func addSubviews() {
        contentView.addSubview(container)
        container.addSubview(timestamp)
        container.addSubview(headerLabel)
        container.addSubview(homeTeamLabel)
        container.addSubview(awayTeamLabel)
        container.addSubview(oddsLabel)
        container.addSubview(outcomeLabel)
        container.addSubview(deleteButton)
        container.addSubview(separator)
        //container.addSubview(betsmart)
    }
    
    private func addConstraints() {
        container.constrain(toSuperviewEdges: UIEdgeInsets(top: C.padding[1],
                                                           left: C.padding[2],
                                                           bottom: -C.padding[1],
                                                           right: -C.padding[2]))
        container.constrain([container.heightAnchor.constraint(greaterThanOrEqualToConstant: 75.0)])
        
        timestamp.constrain([
            timestamp.topAnchor.constraint(equalTo: contentView.topAnchor, constant: C.padding[3]),
            timestamp.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -C.padding[2])])
        
        /*
        betsmart.constrain([
            betsmart.topAnchor.constraint(equalTo: contentView.topAnchor, constant: C.padding[1]/2),
            betsmart.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[1]),
            betsmart.constraint(.width, constant: 48.0),
            betsmart.constraint(.height, constant: 48.0)
        ])
         */
        headerLabel.constrain([
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: C.padding[1]/2),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[2]),
            headerLabel.trailingAnchor.constraint(lessThanOrEqualTo: timestamp.leadingAnchor)])
        homeTeamLabel.constrain([
            homeTeamLabel.topAnchor.constraint(equalTo: timestamp.topAnchor),
            homeTeamLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[2])])
        awayTeamLabel.constrain([
            awayTeamLabel.topAnchor.constraint(equalTo: homeTeamLabel.bottomAnchor, constant: C.padding[1]/2),
            awayTeamLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[2])])
        deleteButton.constrain([
            deleteButton.topAnchor.constraint(equalTo: awayTeamLabel.topAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -C.padding[2]),
            deleteButton.widthAnchor.constraint(equalToConstant: 32.0),
            deleteButton.heightAnchor.constraint(equalToConstant: 32.0)
        ])
        oddsLabel.constrain([
             oddsLabel.topAnchor.constraint(equalTo: deleteButton.topAnchor, constant: C.padding[1]/2),
             oddsLabel.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -C.padding[1])])
        outcomeLabel.constrain([
            outcomeLabel.topAnchor.constraint(equalTo: deleteButton.topAnchor, constant: C.padding[1]/2),
            outcomeLabel.trailingAnchor.constraint(equalTo: oddsLabel.leadingAnchor, constant: -C.padding[1])])
        
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
        //timestamp.setContentHuggingPriority(.required, for: .vertical)
        timestamp.sizeToFit()
        
        /*
        betsmart.setBackgroundImage(#imageLiteral(resourceName: "betsmartWidget"), for: .normal)
        betsmart.frame = CGRect(x: 6.0, y: 6.0, width: 32.0, height: 32.0) // for iOS 10
        betsmart.widthAnchor.constraint(equalToConstant: 32.0).isActive = true
        betsmart.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
        betsmart.tintColor = .transparentWhite
       
        betsmart.tap = { [weak self] in
            self?.didTapBetsmart((self?.viewModel.eventID)!)
        }
         */
        
        deleteButton.image = #imageLiteral(resourceName: "circleCancel")  //.withRenderingMode(.alwaysTemplate)
        
        let tapActionDelete = UITapGestureRecognizer(target: self, action:#selector(self.actionTappedDelete(tapGestureRecognizer:)))
        deleteButton.isUserInteractionEnabled = true
        deleteButton.addGestureRecognizer(tapActionDelete)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func actionTappedDelete(tapGestureRecognizer: UITapGestureRecognizer) {
        self.cellDelegate?.didTapRemoveLeg(nIndex: legIndex!)
    }
}

