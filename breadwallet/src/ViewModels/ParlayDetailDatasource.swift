//
//  ParlayDetailDatasource.swift
//  breadwallet
//
//  Created by MIP on 09/04/2020.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit

class ParlayDetailDataSource: NSObject {
    
    // MARK: - Types
    
    enum Field: String {
        case leg1
        case leg2
        case leg3
        case leg4
        case leg5
        case warning
        case betslider

        var cellType: UITableViewCell.Type {
            switch self {
            case .leg1,.leg2,.leg3,.leg4,.leg5:
                return ParlayLegCell.self
            case .warning:
                return WarningRowCell.self
            case .betslider:
                return ParlaySliderCell.self
            }
        }
        
        func registerCell(forTableView tableView: UITableView) {
            tableView.register(cellType, forCellReuseIdentifier: self.rawValue)
        }
    }
    
    // MARK: - Vars
    var currChoice : EventBetChoice?
    
    fileprivate var fields: [Field]
    fileprivate let viewModel: ParlayBetEntity
    fileprivate let viewController: ParlayDetailViewController
    private var tableView: UITableView!
    
    // MARK: - Init
    
    init(tableView: UITableView, viewModel: ParlayBetEntity, controller: ParlayDetailViewController ) {
        self.viewModel = viewModel
        self.viewController = controller
        
        fields = []
        if viewModel.legs.count >= 1    {  fields.append( .leg1 ) }
        if viewModel.legs.count == 1    {  fields.append(.warning) }
        if viewModel.legs.count >= 2    {  fields.append( .leg2 ) }
        if viewModel.legs.count >= 3    {  fields.append( .leg3 ) }
        if viewModel.legs.count >= 4    {  fields.append( .leg4 ) }
        if viewModel.legs.count >= 5    {  fields.append( .leg5 ) }
        if viewModel.legs.count >= 2    {
            fields.append(.betslider)
        }
        super.init()
        self.tableView = tableView
        self.tableView.dataSource = self
    }
    
    func registerCells(forTableView tableView: UITableView) {
        var fields2 : [Field] = []
        fields2.append( .leg1 )
        fields2.append( .leg2 )
        fields2.append( .leg3 )
        fields2.append( .leg4 )
        fields2.append( .leg5 )
        fields2.append( .warning )
        fields2.append( .betslider)
        fields2.forEach { $0.registerCell(forTableView: tableView) }
    }
}

// MARK: -
extension ParlayDetailDataSource: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.legs.count + 1 // legs + slider row
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let field = fields[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: field.rawValue,
                                                 for: indexPath)

        
        switch field {
            case .leg1:
                let legCell = cell as! ParlayLegCell
                legCell.setParlayLeg( viewModel.legs[0] )
                legCell.legIndex = 0
                legCell.cellDelegate = viewController
            
            case .leg2:
                let legCell = cell as! ParlayLegCell
                legCell.setParlayLeg( viewModel.legs[1] )
                legCell.legIndex = 1
                legCell.cellDelegate = viewController
        
            case .leg3:
                let legCell = cell as! ParlayLegCell
                legCell.setParlayLeg( viewModel.legs[2] )
                legCell.legIndex = 2
                legCell.cellDelegate = viewController
                
            case .leg4:
                let legCell = cell as! ParlayLegCell
                legCell.setParlayLeg( viewModel.legs[3] )
                legCell.legIndex = 3
                legCell.cellDelegate = viewController
            
            case .leg5:
                let legCell = cell as! ParlayLegCell
                legCell.setParlayLeg( viewModel.legs[4] )
                legCell.legIndex = 4
                legCell.cellDelegate = viewController
            
            case .warning:
                let warningCell = cell as! WarningRowCell
                warningCell.title = S.ParlayDetails.warning
            
            case .betslider:
                let betSliderCell = cell as! ParlaySliderCell
                betSliderCell.cellDelegate = viewController
                betSliderCell.viewModel = viewModel
                betSliderCell.updateTotalOdds()
                betSliderCell.recalculateReward(amount: -1)
        }
        
        return cell
    }
}
