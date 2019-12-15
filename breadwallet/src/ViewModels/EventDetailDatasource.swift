//
//  EventDetailDatasource.swift
//  breadwallet
//
//  Created by MIP on 24/11/2019.
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit

class EventDetailDataSource: NSObject {
    
    // MARK: - Types
    
    enum Field: String {
        case date
        case teams
        case moneyline
        case spreads
        case totals
        case blockHeight
        case transactionId
        case gasPrice
        case gasLimit
        case fee

        var cellType: UITableViewCell.Type {
            switch self {
            case .date:
                return EventDateCell.self
            case .teams:
                return EventTeamsLabelCell.self
            case .moneyline:
                return EventBetOptionCell.self
            case .spreads:
                return EventBetOptionSpreadsCell.self
            case .totals:
                return EventBetOptionTotalsCell.self
            case .transactionId:
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
    fileprivate let viewModel: BetEventViewModel
    
    // MARK: - Init
    
    init(viewModel: BetEventViewModel) {
        self.viewModel = viewModel
        
        // define visible rows and order
        fields = [.date]
                
        fields.append(.teams)
        fields.append(.moneyline)
        if (viewModel.hasSpreads)   {
            fields.append(.spreads)
        }
        if (viewModel.hasTotals)   {
            fields.append(.totals)
        }
        //fields.append(.transactionId)
    }
    
    func registerCells(forTableView tableView: UITableView) {
        fields.forEach { $0.registerCell(forTableView: tableView) }
    }
    
    fileprivate func title(forField field: Field) -> String {
        switch field {
        case .date:
            return viewModel.shortTimestamp
        case .teams:
            return ""
        case .moneyline:
            return S.EventDetails.moneyLine
        case .spreads:
            return S.EventDetails.spreadPoints
        case .totals:
            return S.EventDetails.totalPoints
        default:
            return ""
        }
    }
}

// MARK: -
extension EventDetailDataSource: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let field = fields[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: field.rawValue,
                                                 for: indexPath)
        
        if let rowCell = cell as? EventDetailRowCell {
            rowCell.title = title(forField: field)
        }

        switch field {
        case .date:
            let dateCell = cell as! EventDateCell
            dateCell.set(event: viewModel.eventID)
    
        case .teams:
            let teamsCell = cell as! EventTeamsLabelCell
            teamsCell.home = viewModel.txHomeTeam
            teamsCell.away = viewModel.txAwayTeam
        
        case .moneyline:
            let betCell = cell as! EventBetOptionCell
            betCell.option = .MoneyLine
            betCell.home = viewModel.txHomeOdds
            betCell.away = viewModel.txAwayOdds
            betCell.draw = viewModel.txDrawOdds
            
        case .spreads:
            let betCell = cell as! EventBetOptionSpreadsCell
            betCell.option = .SpreadPoints
            betCell.home = viewModel.txHomeSpread
            betCell.away = viewModel.txAwaySpread
            betCell.draw = viewModel.txSpreadPointsFormatted
                
        case .totals:
            let betCell = cell as! EventBetOptionTotalsCell
            betCell.option = .TotalPoints
            betCell.home = viewModel.txOverOdds
            betCell.away = viewModel.txUnderOdds
            betCell.draw = viewModel.txTotalPoints
                
        case .blockHeight:
            let labelCell = cell as! TxLabelCell
            //labelCell.value = viewModel.blockHeight
            
        case .transactionId:
            let addressCell = cell as! TxAddressCell
            //addressCell.set(address: viewModel.transactionHash)
            
        case .gasPrice:
            let labelCell = cell as! TxLabelCell
            //labelCell.value = viewModel.gasPrice ?? ""
            
        case .gasLimit:
            let labelCell = cell as! TxLabelCell
            //labelCell.value = viewModel.gasLimit ?? ""
            
        case .fee:
            let labelCell = cell as! TxLabelCell
            //labelCell.value = viewModel.fee ?? ""
            
        }
        
        return cell

    }
}
