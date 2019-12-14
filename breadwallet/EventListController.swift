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

let eventsHeaderHeight: CGFloat = 152.0
let eventsFooterHeight: CGFloat = 0.0

class EventListController : UIViewController, Subscriber {

    //MARK: - Public
    let currency: CurrencyDef
    
    init(currency: CurrencyDef, walletManager: WalletManager) {
        self.walletManager = walletManager
        self.currency = currency
        self.headerView = EventsHeaderView(currency: currency)
        super.init(nibName: nil, bundle: nil)
        self.eventsTableView = EventsTableViewController(currency: currency, walletManager: walletManager, didSelectEvent: didSelectEvent, didChangeEvents: didChangeEvents )

        if let btcWalletManager = walletManager as? BTCWalletManager {
            headerView.isWatchOnly = btcWalletManager.isWatchOnly
        } else {
            headerView.isWatchOnly = false
        }
    }

    //MARK: - Private
    private let walletManager: WalletManager
    private let headerView: EventsHeaderView
    private let transitionDelegate = ModalTransitionDelegate(type: .transactionDetail)
    private var eventsTableView: EventsTableViewController!
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: searchButton)
        
    }

    private func addSubviews() {
        view.addSubview(headerContainer)
        headerContainer.addSubview(headerView)
        headerContainer.addSubview(searchHeaderview)
    }

    private func addConstraints() {
        headerContainer.constrainTopCorners(height: accountHeaderHeight)
        headerView.constrain(toSuperviewEdges: nil)
        searchHeaderview.constrain(toSuperviewEdges: nil)
    }

    private func addSubscriptions() {
        Store.subscribe(self, selector: { $0.isLoginRequired != $1.isLoginRequired }, callback: { self.isLoginRequired = $0.isLoginRequired })
        Store.subscribe(self, name: .showStatusBar, callback: { _ in
            self.shouldShowStatusBar = true
        })
        Store.subscribe(self, name: .hideStatusBar, callback: { _ in
            self.shouldShowStatusBar = false
        })
    }

    private func setInitialData() {
        searchHeaderview.didCancel = hideSearchHeaderView
        searchHeaderview.didChangeFilters = { [weak self] filters in
            self?.eventsTableView.filters = filters
        }
        headerView.didChangeFilters = { [weak self] filters in
            self?.eventsTableView.filters2 = filters
        }
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
    
    private func didChangeEvents(events: [BetEventViewModel]) -> Void {
        var sports : [(Int, String)] = [(-1, "<Select sport>")]
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
            tournaments[sportID]?.append((-1, "<Select tournament>"))
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
        let eventDetails = EventDetailViewController(event: events[selectedIndex])
        eventDetails.modalPresentationStyle = .overCurrentContext
        eventDetails.transitioningDelegate = transitionDelegate
        eventDetails.modalPresentationCapturesStatusBarAppearance = true
        present(eventDetails, animated: true, completion: nil)
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

