//
//  HomeBetEventCell.swift
//  breadwallet
//
//  Created by MIP on 24/11/2019.
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit

class HomeBetEventCell : UITableViewCell {
    
    static let cellIdentifier = "BetEventCell"

    private let check = UIImageView(image: #imageLiteral(resourceName: "CircleCheck").withRenderingMode(.alwaysTemplate))
    private let titleLabel = UILabel(font: .customBold(size: 18.0), color: .white)
    private let container = Background()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    func set( viewModel: HomeEventViewModel ) {
        accessibilityIdentifier = viewModel.title
        container.currency = viewModel.currency
        titleLabel.text = viewModel.title
        container.setNeedsDisplay()
        check.tintColor = .white
    }
    
    func refreshAnimations() {
    }

    private func setupViews() {
        addSubviews()
        addConstraints()
        setupStyle()
    }

    private func addSubviews() {
        contentView.addSubview(container)
        container.addSubview(check)
        container.addSubview(titleLabel)
    }

    private func addConstraints() {
        container.constrain(toSuperviewEdges: UIEdgeInsets(top: C.padding[1]*0.5,
                                                           left: C.padding[2],
                                                           bottom: -C.padding[1],
                                                           right: -C.padding[2]))
        check.constrain([
            check.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: C.padding[2]),
            check.topAnchor.constraint(equalTo: container.topAnchor, constant: C.padding[2.5])
        ])
        
        titleLabel.constrain([
            titleLabel.leadingAnchor.constraint(equalTo: check.trailingAnchor, constant: C.padding[2]),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: C.padding[2])
            ])
    }

    private func setupStyle() {
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
