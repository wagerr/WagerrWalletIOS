//
//  TxAddressCell.swift
//  breadwallet
//
//  Created by MIP on 2019-12-20.
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit

class EventHeaderCell: EventDetailRowCell {
    
    // MARK: - Accessors
    public var header: String {
        get {
            return headerLabel.text ?? ""
        }
        set {
            headerLabel.text = newValue
        }
    }

    public var error: String {
        get {
            return errorLabel.text ?? ""
        }
        set {
            errorLabel.text = newValue
        }
    }
    
    // MARK: Views
    fileprivate let headerLabel = UILabel(font: UIFont.customBody(size: 24.0))
    fileprivate let errorLabel = UILabel(font: UIFont.customBody(size: 14.0))
    
    private func setupViews() {
        addSubviews()
        addConstraints()
        setupStyle()
    }
    
    override func addSubviews() {
        super.addSubviews()
        container.addSubview(headerLabel)
        container.addSubview(errorLabel)
    }
    
    // MARK: - Init
    override func addConstraints() {
        super.addConstraints()
        
        headerLabel.constrain([
            headerLabel.constraint(.centerX, toView: container),
            headerLabel.constraint(.trailing, toView: container),
            headerLabel.constraint(.top, toView: container),
            headerLabel.constraint(.bottom, toView: container)
            ])
        
        errorLabel.constrain([
            errorLabel.constraint(.centerX, toView: container),
            errorLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: C.padding[1])
        ])
    }
    
    override func setupStyle() {
        super.setupStyle()
        headerLabel.textColor = .primaryText
        errorLabel.textColor = .systemRed
    }

}
