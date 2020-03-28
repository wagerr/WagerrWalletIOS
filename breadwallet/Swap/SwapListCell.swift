//
//  SwapListCell.swift
//  breadwallet
//
//  Created by MIP on 08/02/2020.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit

class SwapListCell: UITableViewCell {

     // MARK: - Views
        
        private let timestamp = UILabel(font: .customBody(size: 16.0), color: .darkText)
        private let descriptionLabel = UILabel(font: .customBody(size: 14.0), color: .primaryText)
        private let amount = UILabel(font: .customBold(size: 18.0))
        private let separator = UIView(color: .separatorGray)
        private let status = UILabel(font: .customBody(size: 16.0), color: .darkText)
        private var pendingConstraints = [NSLayoutConstraint]()
        private var completeConstraints = [NSLayoutConstraint]()
        
        // MARK: Vars
        private var viewModel: SwapViewModel!
        
        // MARK: - Init
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupViews()
        }
        
        func setSwap(_ viewModel: SwapViewModel, isSyncing: Bool ) {
            self.viewModel = viewModel
            
            descriptionLabel.text = "ID: " + viewModel.response.transactionId
            amount.attributedText = viewModel.response.getAttrAmount()
            timestamp.attributedText = viewModel.response.getAttrTimestamp()
            
            status.text = viewModel.response.transactionState.rawValue
            NSLayoutConstraint.activate(completeConstraints)
        }
        
        // MARK: - Private
        
        private func setupViews() {
            addSubviews()
            addConstraints()
            setupStyle()
        }
        
        private func addSubviews() {
            contentView.addSubview(timestamp)
            contentView.addSubview(descriptionLabel)
            contentView.addSubview(status)
            contentView.addSubview(amount)
            contentView.addSubview(separator)
        }
        
        private func addConstraints() {
            timestamp.constrain([
                timestamp.topAnchor.constraint(equalTo: contentView.topAnchor, constant: C.padding[1]),
                timestamp.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[2])])
            descriptionLabel.constrain([
                descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,constant: C.padding[1]),
                descriptionLabel.trailingAnchor.constraint(equalTo: timestamp.trailingAnchor)])
            pendingConstraints = [
                descriptionLabel.centerYAnchor.constraint(equalTo: status.centerYAnchor),
                descriptionLabel.leadingAnchor.constraint(equalTo: status.trailingAnchor, constant: C.padding[1]),
                descriptionLabel.heightAnchor.constraint(equalToConstant: 48.0)]
            completeConstraints = [
                descriptionLabel.topAnchor.constraint(equalTo: timestamp.bottomAnchor),
                descriptionLabel.leadingAnchor.constraint(equalTo: timestamp.leadingAnchor),]
            status.constrain([
                status.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                status.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[2])])
            amount.constrain([
                amount.topAnchor.constraint(equalTo: contentView.topAnchor),
                amount.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                amount.leadingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor, constant: C.padding[6]),
                amount.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -C.padding[2])])
            separator.constrainBottomCorners(height: 0.5)
        }
        
        private func setupStyle() {
            selectionStyle = .none
            amount.textAlignment = .right
            amount.setContentHuggingPriority(.required, for: .horizontal)
            timestamp.setContentHuggingPriority(.required, for: .vertical)
            descriptionLabel.lineBreakMode = .byTruncatingTail
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
