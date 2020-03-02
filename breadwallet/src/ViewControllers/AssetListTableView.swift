//
//  AssetListTableView.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-12-04.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit

class AssetListTableView: UITableViewController, Subscriber {

    var didSelectCurrency: ((CurrencyDef) -> Void)?
    var didTapBet: ((CurrencyDef) -> Void)?
    var didTapBuy: ((CurrencyDef) -> Void)?
    var didTapSecurity: (() -> Void)?
    var didTapSupport: (() -> Void)?
    var didTapSettings: (() -> Void)?
    var didTapAddWallet: (() -> Void)?
    private let assetHeight: CGFloat = 85.0
    private let bettingHeight: CGFloat = 65.0
    private let menuHeight: CGFloat = 53.0
    private let manageWalletContent = (S.TokenList.manageTitle, #imageLiteral(resourceName: "PlaylistPlus"))

    // MARK: - Init
    
    init() {
        super.init(style: .grouped)
    }

    override func viewDidLoad() {
        tableView.backgroundColor = .whiteBackground
        tableView.register(HomeScreenCell.self, forCellReuseIdentifier: HomeScreenCell.cellIdentifier)
        tableView.register(HomeBetEventCell.self, forCellReuseIdentifier: HomeBetEventCell.cellIdentifier)
        tableView.register(HomeSwapCell.self, forCellReuseIdentifier: HomeSwapCell.cellIdentifier)
        tableView.register(MenuCell.self, forCellReuseIdentifier: MenuCell.cellIdentifier)
        tableView.separatorStyle = .none
        tableView.sectionHeaderHeight = CGFloat(30.0)
        tableView.sectionFooterHeight = CGFloat(40.0)
        
        tableView.reloadData()
        
        Store.subscribe(self, selector: {
            var result = false
            let oldState = $0
            let newState = $1
            $0.displayCurrencies.forEach { currency in
                if oldState[currency]?.balance != newState[currency]?.balance
                    || oldState[currency]?.currentRate?.rate != newState[currency]?.currentRate?.rate
                    || oldState[currency]?.maxDigits != newState[currency]?.maxDigits {
                    result = true
                }
            }
            return result
        }, callback: { _ in
            self.tableView.reloadData()
        })
        
        Store.subscribe(self, selector: {
            $0.displayCurrencies.map { $0.code } != $1.displayCurrencies.map { $0.code }
        }, callback: { _ in
                self.tableView.reloadData()
            })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.visibleCells.forEach {
            if let cell = $0 as? HomeScreenCell {
                cell.refreshAnimations()
            }
        }
    }
    
    func reload() {
        tableView.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Data Source
    
    enum Section: Int {
        case assets
        case events
        case buy
        case menu
    }

    enum Menu: Int {
        case settings
        case security
        case support
        
        var content: (String, UIImage) {
            switch self {
            case .settings:
                return (S.MenuButton.settings, #imageLiteral(resourceName: "Settings"))
            case .security:
                return (S.MenuButton.security, #imageLiteral(resourceName: "Shield"))
            case .support:
                return (S.MenuButton.support, #imageLiteral(resourceName: "Faq"))
            }
        }
        
        static let allItems: [Menu] = [.settings, .security, .support]
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        
        switch section {
        case .assets:
            return Store.state.displayCurrencies.count  // remove +1 to hide "Manage wallets" menu
        case .events:
            return 1
        case .buy:
            return 1
        case .menu:
            return Menu.allItems.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else { return 0 }
        switch section {
        case .assets:
            return isAddWalletRow(row: indexPath.row) ? menuHeight : assetHeight
        case .events:
            return bettingHeight
        case .buy:
            return bettingHeight
        case .menu:
            return menuHeight
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }

         // disable token management
/*
        if section == .assets && isAddWalletRow(row: indexPath.row) {
            let cell = tableView.dequeueReusableCell(withIdentifier: MenuCell.cellIdentifier, for: indexPath) as! MenuCell
            cell.set(title: manageWalletContent.0, icon: manageWalletContent.1)
            return cell
        }
*/
        switch section {
        case .assets:
            let currency = Store.state.displayCurrencies[indexPath.row]
            let viewModel = AssetListViewModel(currency: currency)
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeScreenCell.cellIdentifier, for: indexPath) as! HomeScreenCell
            cell.set(viewModel: viewModel)
            return cell
            
        case .events:
            var viewModel : HomeEventViewModel!
            viewModel = HomeEventViewModel(currency: Currencies.btc, title: "Sports Betting")
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeBetEventCell.cellIdentifier, for: indexPath) as! HomeBetEventCell
            cell.set(viewModel: viewModel)
            return cell
        case .buy:
            var viewModel : HomeSwapViewModel!
            viewModel = HomeSwapViewModel(currency: Currencies.btc, title:
                NSMutableAttributedString()
                    .bold("InstaSwap")
                    .normal(" by instaswap.io"))
            let cell = tableView.dequeueReusableCell(withIdentifier: HomeSwapCell.cellIdentifier, for: indexPath) as! HomeSwapCell
            cell.set(viewModel: viewModel)
            return cell
        case .menu:
            let cell = tableView.dequeueReusableCell(withIdentifier: MenuCell.cellIdentifier, for: indexPath) as! MenuCell
            guard let item = Menu(rawValue: indexPath.row) else { return cell }
            let content = item.content
            cell.set(title: content.0, icon: content.1)
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }

        switch section {
        case .assets:
            return S.HomeScreen.portfolio
        case .events:
            return S.HomeScreen.betting
        case .buy:
            return S.HomeScreen.buy
        case .menu:
            return S.HomeScreen.admin
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView,
            let label = header.textLabel else { return }
        label.text = label.text?.capitalized
        label.textColor = .darkText
        label.font = .customBody(size: 12.0)
        header.tintColor = tableView.backgroundColor
    }
    
    // MARK: - Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        switch section {
        case .assets:
            isAddWalletRow(row: indexPath.row) ? didTapAddWallet?() : didSelectCurrency?(Store.state.displayCurrencies[indexPath.row])
        case .events:
            didTapBet?( Currencies.btc )
        case .buy:
            didTapBuy?( Currencies.btc )
        case .menu:
            guard let item = Menu(rawValue: indexPath.row) else { return }
            switch item {
            case .settings:
                didTapSettings?()
            case .security:
                didTapSecurity?()
            case .support:
                didTapSupport?()
            }
        }
    }

    private func isAddWalletRow(row: Int) -> Bool {
        return row == Store.state.displayCurrencies.count
    }
}
