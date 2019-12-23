//
//  TxAddressCell.swift
//  breadwallet
//
//  Created by MIP on 2019-12-20.
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit

class LinkCell: EventDetailRowCell {
    
    // MARK: Views
    internal let linkButton = UIButton(type: .system)
    
    private func setupViews() {
        addSubviews()
        addConstraints()
        setupStyle()
    }
    
    override func addSubviews() {
        super.addSubviews()
        container.addSubview(linkButton)
    }
    
    // MARK: - Init
    override func addConstraints() {
        super.addConstraints()
        
        linkButton.constrain([
            linkButton.constraint(.centerX, toView: container),
            linkButton.constraint(.trailing, toView: container),
            linkButton.constraint(.top, toView: container),
            linkButton.constraint(.bottom, toView: container)
            ])
    }
    
    func set(text: String, txHash: String) {
        linkButton.setTitle( text, for: .normal)
        linkButton.tap = strongify(self) { myself in
            myself.linkButton.tempDisable()
            EventDetailViewController.navigate(to: txHash, type: EventExplorerType.transaction)
        }
    }

}
