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
        case betslider

        var cellType: UITableViewCell.Type {
            switch self {
            case .leg1,.leg2,.leg3,.leg4,.leg5:
                return ParlayLegCell.self
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
        if viewModel.legs.count >= 2    {  fields.append( .leg2 ) }
        if viewModel.legs.count >= 3    {  fields.append( .leg3 ) }
        if viewModel.legs.count >= 4    {  fields.append( .leg4 ) }
        if viewModel.legs.count >= 5    {  fields.append( .leg5 ) }
        fields.append(.betslider)
        
        super.init()
        self.tableView = tableView
        self.tableView.dataSource = self
    }
    
    func registerCells(forTableView tableView: UITableView) {
        fields.forEach { $0.registerCell(forTableView: tableView) }
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
            
            case .leg2:
                let legCell = cell as! ParlayLegCell
                legCell.setParlayLeg( viewModel.legs[1] )
        
            case .leg3:
                let legCell = cell as! ParlayLegCell
                legCell.setParlayLeg( viewModel.legs[2] )
                
            case .leg4:
                let legCell = cell as! ParlayLegCell
                legCell.setParlayLeg( viewModel.legs[3] )
            
            case .leg5:
                let legCell = cell as! ParlayLegCell
                legCell.setParlayLeg( viewModel.legs[4] )
            
            case .betslider:
                let betSliderCell = cell as! ParlaySliderCell
                betSliderCell.cellDelegate = viewController
                betSliderCell.viewModel = viewModel
        }
        
        return cell
    }
}
