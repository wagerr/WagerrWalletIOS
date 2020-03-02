//
//  TxDetailDataSource.swift
//  Wagerr Pro
//
//  Created by MIP on 2020-02-08.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit

class SwapDetailDataSource: NSObject {
    
    // MARK: - Types
    
    enum Field: String {
        case transactionId
        case deposit
        case receive
        case refundWallet
        case receiveWallet
        case depositWallet
        case state
        case timestamp
        
        var cellType: UITableViewCell.Type {
            switch self {
            case .refundWallet, .receiveWallet, .depositWallet, .transactionId:
                return TxAddressCell.self
            default:
                return TxLabelCell.self
            }
        }
        
        func registerCell(forTableView tableView: UITableView) {
            tableView.register(cellType, forCellReuseIdentifier: self.rawValue)
        }
    }
    
    // MARK: - Vars
    
    fileprivate var fields: [Field]
    fileprivate let viewModel: SwapViewModel
    
    // MARK: - Init
    
    init(viewModel: SwapViewModel) {
        self.viewModel = viewModel
        
        // define visible rows and order
        fields = [.transactionId, .timestamp, .state, .deposit, .depositWallet, .receive, .receiveWallet, .refundWallet ]
    }
    
    func registerCells(forTableView tableView: UITableView) {
        fields.forEach { $0.registerCell(forTableView: tableView) }
    }
    
    fileprivate func title(forField field: Field) -> String {
        switch field {
        case .transactionId:
            return S.Instaswap.transactionId
        case .deposit:
            return String.init(format: S.Instaswap.deposit, viewModel.response.depositCoin)
        case .receive:
            return String.init(format: S.Instaswap.receive, viewModel.response.receiveCoin)
        case .refundWallet:
            return S.Instaswap.refundWallet
        case .receiveWallet:
            return S.Instaswap.receiveWallet
        case .depositWallet:
            return S.Instaswap.depositWallet
        case .timestamp:
            return S.Instaswap.timestampTitle
        case .state:
            return S.Instaswap.stateTitle
        default:
            return ""
        }
    }
}

// MARK: -
extension SwapDetailDataSource: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let field = fields[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: field.rawValue,
                                                 for: indexPath)
        
        if let rowCell = cell as? TxAddressCell {
            rowCell.title = title(forField: field)
        }
        
        if let rowCell = cell as? TxLabelCell {
            rowCell.title = title(forField: field)
        }

        switch field {
        case .refundWallet:
            let refundWalletCell = cell as! TxAddressCell
            refundWalletCell.set(address: viewModel.response.refundWallet)
        case .receiveWallet:
            let receiveWalletCell = cell as! TxAddressCell
            receiveWalletCell.set(address: viewModel.response.receiveWallet)
        case .depositWallet:
            let depositWalletCell = cell as! TxAddressCell
            depositWalletCell.set(address: viewModel.response.depositWallet)
        case .transactionId:
            let transactionCell = cell as! TxAddressCell
            transactionCell.set(address: viewModel.response.transactionId)
        case .deposit:
            let depositCell = cell as! TxLabelCell
            depositCell.value = viewModel.response.depositAmount
        case .receive:
            let receiveCell = cell as! TxLabelCell
            receiveCell.value = viewModel.response.receivingAmount + " " + viewModel.response.receiveCoin
        case .timestamp:
            let timestampCell = cell as! TxLabelCell
            timestampCell.value = viewModel.response.timestamp
        case .state:
            let stateCell = cell as! TxLabelCell
            stateCell.value = viewModel.response.transactionState.rawValue
        }
        
        return cell

    }
    
}
