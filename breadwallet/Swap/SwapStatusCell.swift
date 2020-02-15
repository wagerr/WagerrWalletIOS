//
//  TxStatusCell.swift
//  Wagerr Pro
//
//  Created by MIP on 2020-02-08
//  Copyright © 2020 Wagerr. All rights reserved.
//

import UIKit

class SwapStatusCell: UITableViewCell, Subscriber {

    // MARK: - Views
    
    private let container = UIView()
    private lazy var statusLabel: UILabel = {
        let label = UILabel(font: UIFont.customBody(size: 14.0))
        label.textColor = .darkText
        label.textAlignment = .center
        return label
    }()
    //private let statusIndicator = TxStatusIndicator(width: 238.0)
    
    // MARK: - Init
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    private func setupViews() {
        addSubviews()
        addConstraints()
    }
    
    private func addSubviews() {
        contentView.addSubview(container)
        container.addSubview(statusLabel)
    }
    
    private func addConstraints() {

        container.constrain(toSuperviewEdges: UIEdgeInsets(top: C.padding[1],
                                                           left: C.padding[1],
                                                           bottom: -C.padding[2],
                                                           right: -C.padding[1]))
        
        statusLabel.constrain([
            statusLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            statusLabel.topAnchor.constraint(equalTo: container.topAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
    }
    
    // MARK: -
    
    func set(txInfo: SwapViewModel) {
        Store.lazySubscribe(self,
                            selector: {
                                guard let oldTransactions = $0[txInfo.currency]?.swapTransactions else { return false}
                                guard let newTransactions = $1[txInfo.currency]?.swapTransactions else { return false}
                                return oldTransactions != newTransactions },
                            callback: { [weak self] state in
                                guard let `self` = self,
                                    let updatedTx = state[txInfo.currency]?.swapTransactions.filter({ $0.response.transactionId == txInfo.response.transactionId }).first else { return }
                                DispatchQueue.main.async {
                                    self.update(status: updatedTx.response.transactionState)
                                }
        })
        
        update(status: txInfo.response.transactionState)
    }
    
    private func update(status: SwapTransactionState) {
        //statusIndicator.status = status
        statusLabel.text = status.rawValue
    }
    
    deinit {
        Store.unsubscribe(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
