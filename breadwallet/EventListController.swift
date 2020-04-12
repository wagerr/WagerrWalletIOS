//
//  EventListController.swift
//  breadwallet
//
//  Created by MIP on 24/11/2019.
//  Copyright © 2019 Wagerr Ltd.. All rights reserved.
//

import UIKit
import BRCore
import MachO

let eventsHeaderHeight: CGFloat = 172.0
let eventsFooterHeight: CGFloat = 0.0

protocol BetSettingsDelegate    {
    func didTapBetSettingsBack()
}

class EventListController : UIViewController, Subscriber, BetSettingsDelegate {

    //MARK: - Public
    let currency: CurrencyDef
    
    init(currency: CurrencyDef, walletManager: WalletManager) {
        self.walletManager = walletManager
        self.currency = currency
        self.headerView = EventsHeaderView(currency: currency)
        
        let btcWalletManager = walletManager as? BTCWalletManager
        if btcWalletManager != nil {
            headerView.isWatchOnly = btcWalletManager!.isWatchOnly
            self.parlayBet = btcWalletManager!.parlayBet
        } else {
            headerView.isWatchOnly = false
            self.parlayBet = nil
        }
        super.init(nibName: nil, bundle: nil)
        self.eventsTableView = EventsTableViewController(currency: currency, walletManager: walletManager, didSelectEvent: didSelectEvent, didChangeEvents: didChangeEvents, didTapBetsmart: didTapBetsmart )
    }

    //MARK: - Private
    private let walletManager: WalletManager
    private let headerView: EventsHeaderView
    private let transitionDelegate = ModalTransitionDelegate(type: .transactionDetail)
    private var eventsTableView: EventsTableViewController!
    private let parlayBet: ParlayBetEntity?
    private let parlayOpenButton = UIButton(type: .custom)
    private var isLoginRequired = false
    private let searchHeaderview: EventSearchHeaderView = {
        let view = EventSearchHeaderView()
        view.isHidden = true
        return view
    }()
    private let headerContainer = UIView()
    private var loadingTimer: Timer?
    private var shouldShowStatusBar: Bool = true {
        didSet {
            if oldValue != shouldShowStatusBar {
                UIView.animate(withDuration: C.animationDuration) {
                    self.setNeedsStatusBarAppearanceUpdate()
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // detect jailbreak so we can throw up an idiot warning, in viewDidLoad so it can't easily be swizzled out
        if !E.isSimulator {
            var s = stat()
            var isJailbroken = (stat("/bin/sh", &s) == 0) ? true : false
            for i in 0..<_dyld_image_count() {
                guard !isJailbroken else { break }
                // some anti-jailbreak detection tools re-sandbox apps, so do a secondary check for any MobileSubstrate dyld images
                if strstr(_dyld_get_image_name(i), "MobileSubstrate") != nil {
                    isJailbroken = true
                }
            }
            NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: nil) { note in
                self.showJailbreakWarnings(isJailbroken: isJailbroken)
            }
            showJailbreakWarnings(isJailbroken: isJailbroken)
        }

        setupNavigationBar()
        addTransactionsView()
        addSubviews()
        addConstraints()
        addSubscriptions()
        setInitialData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        shouldShowStatusBar = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        headerView.setBalances()
        if walletManager.peerManager?.connectionStatus == BRPeerStatusDisconnected {
            DispatchQueue.walletQueue.async { [weak self] in
                self?.walletManager.peerManager?.connect()
            }
        }
    }
    
    // MARK: -
    
    private func setupNavigationBar() {
        let searchButton = UIButton(type: .system)
        searchButton.setImage(#imageLiteral(resourceName: "SearchIcon"), for: .normal)
        searchButton.frame = CGRect(x: 0.0, y: 12.0, width: 22.0, height: 22.0) // for iOS 10
        searchButton.widthAnchor.constraint(equalToConstant: 22.0).isActive = true
        searchButton.heightAnchor.constraint(equalToConstant: 22.0).isActive = true
        searchButton.tintColor = .white
        searchButton.tap = showSearchHeaderView
        
        let settingButton = UIButton(type: .system)
        settingButton.setImage(#imageLiteral(resourceName: "SettingsIcon"), for: .normal)
        settingButton.frame = CGRect(x: 0.0, y: 12.0, width: 22.0, height: 22.0) // for iOS 10
        settingButton.widthAnchor.constraint(equalToConstant: 22.0).isActive = true
        settingButton.heightAnchor.constraint(equalToConstant: 22.0).isActive = true
        settingButton.tintColor = .white
        settingButton.tap = showBetSettings
        
        navigationItem.rightBarButtonItems = [ UIBarButtonItem(customView: searchButton), UIBarButtonItem(customView: settingButton) ]
    }

    private func addSubviews() {
        view.addSubview(headerContainer)
        headerContainer.addSubview(headerView)
        headerContainer.addSubview(searchHeaderview)
        view.addSubview(parlayOpenButton)
    }

    private func addConstraints() {
        headerContainer.constrainTopCorners(height: eventsHeaderHeight)
        headerView.constrain(toSuperviewEdges: nil)
        searchHeaderview.constrain(toSuperviewEdges: nil)
        
        parlayOpenButton.translatesAutoresizingMaskIntoConstraints = false
        parlayOpenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor , constant: -30).isActive = true
        parlayOpenButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive = true
        parlayOpenButton.heightAnchor.constraint(equalToConstant: 48.0).isActive = true
        parlayOpenButton.widthAnchor.constraint(equalToConstant: 48.0).isActive = true
    }

    private func addSubscriptions() {
        Store.subscribe(self, selector: { $0.isLoginRequired != $1.isLoginRequired }, callback: { self.isLoginRequired = $0.isLoginRequired })
        Store.subscribe(self, name: .showStatusBar, callback: { _ in
            self.shouldShowStatusBar = true
        })
        Store.subscribe(self, name: .hideStatusBar, callback: { _ in
            self.shouldShowStatusBar = false
        })
        
        Store.subscribe(self, selector: { $0[self.currency]?.syncState != $1[self.currency]?.syncState },
                        callback: { state in
                            guard let syncState = state[self.currency]?.syncState else { return }
                            switch syncState {
                            case .success:
                                (self.walletManager as! BTCWalletManager).updateEvents()
                            default:
                                break
                            }
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        
    }

    @objc func willEnterForeground() {
        (walletManager as! BTCWalletManager).updateEvents()
    }
    
    private func setInitialData() {
        searchHeaderview.didCancel = hideSearchHeaderView
        searchHeaderview.didChangeFilters = { [weak self] filters in
            self?.eventsTableView.filters = filters
        }
        headerView.didChangeFilters = { [weak self] filters in
            self?.eventsTableView.filters2 = filters
        }
        
        parlayOpenButton.setTitle( String.init(parlayBet!.legCount) , for: .normal)
        parlayOpenButton.titleLabel!.font = UIFont.customBold(size: 20.0)
        parlayOpenButton.frame.size = CGSize(width: 48, height: 48)
        parlayOpenButton.backgroundColor = .systemOrange
        parlayOpenButton.clipsToBounds = true
        parlayOpenButton.layer.cornerRadius = 24
        parlayOpenButton.layer.borderWidth = 0.0
        
        let tapActionOpenParlay = UITapGestureRecognizer(target: self, action:#selector(self.actionTappedOpenParlay(tapGestureRecognizer:)))
        parlayOpenButton.isUserInteractionEnabled = true
        parlayOpenButton.addGestureRecognizer(tapActionOpenParlay)
    }
    
    @objc func actionTappedOpenParlay(tapGestureRecognizer: UITapGestureRecognizer) {
        Store.perform(action: RootModalActions.Present(modal: .sendparlay(parlay: (walletManager as! BTCWalletManager).parlayBet, didChangeLegs: didChangeLegs) ))
    }

    private func addTransactionsView() {
        view.backgroundColor = .whiteBackground
        addChildViewController(eventsTableView, layout: {
            if #available(iOS 11.0, *) {
                eventsTableView.view.constrain([
                eventsTableView.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                eventsTableView.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                eventsTableView.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                eventsTableView.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                ])
            } else {
                eventsTableView.view.constrain(toSuperviewEdges: nil)
            }
        })
    }

    func containsKey(a:[(Int, String)], v:(Int,String)) -> Bool {
        let (c1, _) = v
        for (v1, _) in a { if v1 == c1 { return true } }
        return false
    }
    
    private func didChangeLegs()    {
        if parlayBet?.legCount == 0 {
            parlayOpenButton.isHidden = true
        }
        else    {
            parlayOpenButton.isHidden = false
            parlayOpenButton.setTitle( String.init(parlayBet!.legCount) , for: .normal)
        }
    }
    
    private func didChangeEvents(events: [BetEventViewModel]) -> Void {
        var sports : [(Int, String)] = [(-1, "Sport")]
        let sportsTuples : [(Int, String)] = events.reduce([], { initialValue, collectionElement in
            let iv : [(Int, String)] = initialValue
            let tuple = (  Int(collectionElement.sportID), collectionElement.txSport )
            return containsKey(a:iv, v:tuple) ? iv : iv + [tuple]
        })
        let sortedSportsTuples = sportsTuples.sorted { (n1:(Int,String), n2:(Int,String)) -> Bool in return n1.1 < n2.1 }
        sports.append(contentsOf: sortedSportsTuples)
        
        var tournaments = [ Int: [(Int,String)] ]()
        for (sportID, _) in sports {
            tournaments[sportID] = [(Int,String)]()
            tournaments[sportID]?.append((-1, "League"))
            let sportTournaments : [(Int, String)] = events.filter { $0.sportID==sportID }.reduce([], { initialValue, collectionElement in
                let iv : [(Int, String)] = initialValue
                let tuple = (  Int(collectionElement.tournamentID), collectionElement.txTournament )
                return containsKey(a:iv, v:tuple) ? iv : iv + [tuple]
            })
            let sortedSportTournaments = sportTournaments.sorted(by: { (n1:(Int,String), n2:(Int,String)) -> Bool in return n1.1 < n2.1 } )
            tournaments[sportID]?.append(contentsOf: sortedSportTournaments)
        }
        headerView.updatePickers(sports: sports, tournaments: tournaments)
    }

    private func didSelectEvent(events: [BetEventViewModel], selectedIndex: Int) -> Void {
        Store.perform(action: RootModalActions.Present(modal: .sendbet(event: events[selectedIndex], didChangeLegs: didChangeLegs ) ))
    }
    
    func didTapBetsmart(eventID : UInt64)   {
        var style = "light"
        if #available(iOS 13.0, *) {
            if UIScreen.main.traitCollection.userInterfaceStyle == .dark    {
                style="dark"
            }
        }
        
        let betsmartDetails = WebViewController(theURL: String.init(format: "https://betsmart.app/teaser-event?id=%d&mode=%@&source=wagerr", eventID, style))
        betsmartDetails.modalPresentationStyle = .overCurrentContext
        betsmartDetails.transitioningDelegate = transitionDelegate
        betsmartDetails.modalPresentationCapturesStatusBarAppearance = true
        present(betsmartDetails, animated: true, completion: nil)
    }
    

    private func showJailbreakWarnings(isJailbroken: Bool) {
        guard isJailbroken else { return }
        let totalSent = walletManager.wallet?.totalSent ?? 0
        let message = totalSent > 0 ? S.JailbreakWarnings.messageWithBalance : S.JailbreakWarnings.messageWithBalance
        let alert = UIAlertController(title: S.JailbreakWarnings.title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.JailbreakWarnings.ignore, style: .default, handler: nil))
        if totalSent > 0 {
            alert.addAction(UIAlertAction(title: S.JailbreakWarnings.wipe, style: .default, handler: nil)) //TODO - implement wipe
        } else {
            alert.addAction(UIAlertAction(title: S.JailbreakWarnings.close, style: .default, handler: { _ in
                exit(0)
            }))
        }
        present(alert, animated: true, completion: nil)
    }
    
    private func showSearchHeaderView() {
        let navBarHeight: CGFloat = 44.0
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        var contentInset = self.eventsTableView.tableView.contentInset
        var contentOffset = self.eventsTableView.tableView.contentOffset
        contentInset.top += navBarHeight
        contentOffset.y -= navBarHeight
        self.eventsTableView.tableView.contentInset = contentInset
        self.eventsTableView.tableView.contentOffset = contentOffset
        UIView.transition(from: self.headerView,
                          to: self.searchHeaderview,
                          duration: C.animationDuration,
                          options: [.transitionFlipFromBottom, .showHideTransitionViews, .curveEaseOut],
                          completion: { _ in
                            self.searchHeaderview.triggerUpdate()
                            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    private func showBetSettings() {
        self.navigationController?.navigationBar.tintColor = .primaryText
        let betSettingController = BetSettingsViewController()
        betSettingController.delegate = self
        self.navigationController?.pushViewController(betSettingController, animated: true)
    }
    
    func didTapBetSettingsBack()    {
        eventsTableView.reload()
    }
    
    private func hideSearchHeaderView() {
        let navBarHeight: CGFloat = 44.0
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        var contentInset = self.eventsTableView.tableView.contentInset
        contentInset.top -= navBarHeight
        self.eventsTableView.tableView.contentInset = contentInset
        UIView.transition(from: self.searchHeaderview,
                          to: self.headerView,
                          duration: C.animationDuration,
                          options: [.transitionFlipFromTop, .showHideTransitionViews, .curveEaseOut],
                          completion: { _ in
                            self.setNeedsStatusBarAppearanceUpdate()
        })
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return searchHeaderview.isHidden ? .lightContent : .default
    }

    override var prefersStatusBarHidden: Bool {
        return !shouldShowStatusBar
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

