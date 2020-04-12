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
        case header
        case date
        case teams
        case moneyline
        case spreads
        case totals
        case betslider

        var cellType: UITableViewCell.Type {
            switch self {
            case .header:
                return EventHeaderCell.self
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
            case .betslider:
                return EventSliderCell.self
            }
        }
        
        func registerCell(forTableView tableView: UITableView) {
            tableView.register(cellType, forCellReuseIdentifier: self.rawValue)
        }
    }
    
    // MARK: - Vars
    var sliderCell : EventSliderCell?
    var moneyLineCell : EventBetOptionCell?
    var spreadsCell : EventBetOptionSpreadsCell?
    var totalsCell : EventBetOptionTotalsCell?
    var currChoice : EventBetChoice?
    
    fileprivate var fields: [Field]
    fileprivate let viewModel: BetEventViewModel
    fileprivate let viewController: EventDetailViewController
    private var tableView: UITableView!
    
    var didTapBetsmart : (String) -> Void
    
    // MARK: - Init
    
    init(tableView: UITableView, viewModel: BetEventViewModel, controller: EventDetailViewController, didTapBetsmart : @escaping(String) -> Void) {
        self.viewModel = viewModel
        self.viewController = controller
        self.didTapBetsmart = didTapBetsmart
        fields = []
        
        super.init()
        self.tableView = tableView
        self.tableView.dataSource = self

        self.prepareBetLayout(choice: nil)
    }
    
    func prepareBetLayout( choice: EventBetChoice? ) -> Int {
        var sliderPos = 0
        fields = [.header, .date]
                
        fields.append(.teams)
        fields.append(.moneyline)
        if (choice != nil && choice?.option == EventBetOption.MoneyLine) {
            fields.append(.betslider)
            sliderPos = fields.count - 1
        }
        if (viewModel.hasSpreads)   {
            fields.append(.spreads)
            if (choice != nil && choice?.option == EventBetOption.SpreadPoints) {
                fields.append(.betslider)
                sliderPos = fields.count - 1
            }
        }
        if (viewModel.hasTotals)   {
            fields.append(.totals)
            if (choice != nil && choice?.option == EventBetOption.TotalPoints) {
                fields.append(.betslider)
                sliderPos = fields.count - 1
            }
        }
        currChoice = choice
        return sliderPos
    }
    
    func registerCells(forTableView tableView: UITableView) {
        fields.forEach { $0.registerCell(forTableView: tableView) }
        // register betSlider cell manually
        var fields2 : [Field] = []
        fields2.append(.betslider)
        fields2.forEach { $0.registerCell(forTableView: tableView) }
    }
    
    fileprivate func title(forField field: Field) -> String {
        switch field {
        case .header:
            return ""
        case .date:
            return viewModel.shortTimestamp
        case .teams:
            return ""
        case .moneyline:
            return S.EventDetails.moneyLine
        case .betslider:
            return ""
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
        case .header:
            let headerCell = cell as! EventHeaderCell
            headerCell.header = viewModel.title
            let balanceAmount = Currencies.btc.state?.balance != nil ? (Currencies.btc.state?.balance!.asUInt64)!/C.satoshis : 0
            headerCell.error = (Float(balanceAmount) < W.BetAmount.min) ? String.init(format: S.Betting.errorMinimum, Int(W.BetAmount.min), Currencies.btc.code) : ""

        case .date:
            let dateCell = cell as! EventDateCell
            dateCell.set(event: viewModel.eventID)
    
        case .teams:
            let teamsCell = cell as! EventTeamsLabelCell
            teamsCell.home = viewModel.txHomeTeam
            teamsCell.away = viewModel.txAwayTeam
            teamsCell.didTapBetsmart = didTapBetsmart
        
        case .moneyline:
            let betCell = cell as! EventBetOptionCell
            betCell.option = .MoneyLine
            betCell.home = viewModel.txHomeOdds
            betCell.away = viewModel.txAwayOdds
            betCell.draw = viewModel.txDrawOdds
            self.moneyLineCell = betCell
            betCell.cellDelegate = viewController
            
        case .spreads:
            let betCell = cell as! EventBetOptionSpreadsCell
            betCell.option = .SpreadPoints
            betCell.home = viewModel.txHomeSpread
            betCell.away = viewModel.txAwaySpread
            betCell.draw = viewModel.txSpreadPointsFormatted
            self.spreadsCell = betCell
            betCell.cellDelegate = viewController
                
        case .totals:
            let betCell = cell as! EventBetOptionTotalsCell
            betCell.option = .TotalPoints
            betCell.home = viewModel.txOverOdds
            betCell.away = viewModel.txUnderOdds
            betCell.draw = viewModel.txTotalPoints
            self.totalsCell = betCell
            betCell.cellDelegate = viewController
                
        case .betslider:
            let betSliderCell = cell as! EventSliderCell
            self.sliderCell = betSliderCell
            self.sliderCell?.betChoice = currChoice
            betSliderCell.cellDelegate = viewController
            
        }
        
        return cell

    }
    
    func cleanBetOptions(choice: EventBetChoice)    {
        self.moneyLineCell?.restoreLabelsSize(choice: choice)
        self.spreadsCell?.restoreLabelsSize(choice: choice)
        self.totalsCell?.restoreLabelsSize(choice: choice)
    }
    
    func registerBetChoice(choice: EventBetChoice)  {
        cleanBetOptions(choice: choice)
        currChoice = choice
        guard self.sliderCell != nil else {
            return
        }
        self.sliderCell?.betChoice = choice
        self.sliderCell?.recalculateReward(amount: -1)
    }
    
    func updateLegButton( mode : LegButtonMode )    {
        guard self.sliderCell != nil else {
                return
            }
        self.sliderCell?.updateLegButton(mode: mode)
    }
}
