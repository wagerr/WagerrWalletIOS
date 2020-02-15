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

    private let check = UIImageView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
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
        let checkImage = #imageLiteral(resourceName: "BetIcon").withRenderingMode(.alwaysTemplate)
        check.image = checkImage
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
            check.topAnchor.constraint(equalTo: container.topAnchor, constant: C.padding[2.5]),
            check.widthAnchor.constraint(equalToConstant: CGFloat(16.0)),
            check.heightAnchor.constraint(equalToConstant: CGFloat(16.0))
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
