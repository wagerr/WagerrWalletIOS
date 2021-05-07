//
//  EventDetailViewController.swift
//  breadwallet
//
//  Created by MIP on 24/11/2019.
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit
import BRCore

private extension C {
    static let statusRowHeight: CGFloat = 48.0
    static let compactContainerHeight: CGFloat = 322.0
    static let expandedContainerHeight: CGFloat = 546.0
    static let detailsButtonHeight: CGFloat = 65.0
}

protocol EventBetOptionDelegate  {
    func didTapBetOption(choice: EventBetChoice, isSelected: Bool)
}

protocol EventBetSliderDelegate  {
    func didTapOk(choice: EventBetChoice, amount: Int)
    func didTapCancel()
    func didTapAddLeg(choice: EventBetChoice)
    func didTapRemoveLeg(choice: EventBetChoice)
}

class EventDetailViewController: UIViewController, Subscriber, EventBetOptionDelegate, EventBetSliderDelegate, Trackable {
    
    // MARK: - Private Vars
    
    private let container = UIView()
    private let tapView = UIView()
    //private let header: ModalHeaderView
    private let footer = UIView()
    private let separator = UIView()
    private let tableView = UITableView()
    private let parlayOpenButton = UIButton(type: .custom)
    private let parlayBet: ParlayBetEntity?
    
    private var sliderPosToRemove : Int = 0
    private var containerHeightConstraint: NSLayoutConstraint!
    
    private var event: BetEventViewModel {
        didSet {
            reload()
        }
    }
    private var viewModel: BetEventViewModel
    private var walletManager: BTCWalletManager
    private var dataSource: EventDetailDataSource?
    private var isExpanded: Bool = true
    
    private var sender: BitcoinSender
    private let verifyPinTransitionDelegate = PinTransitioningDelegate()
    private let confirmTransitioningDelegate = PinTransitioningDelegate()
    var presentVerifyPin: ((String, @escaping ((String) -> Void))->Void)?
    var onPublishSuccess: (()->Void)?
    var didChangeLegs: (()->Void)
    
    private let transitionDelegate = ModalTransitionDelegate(type: .transactionDetail)
    
    private var compactContainerHeight: CGFloat {
        return C.expandedContainerHeight
    }
    
    private var expandedContainerHeight: CGFloat {
        let maxHeight = view.frame.height - C.padding[4]
        var contentHeight =  tableView.contentSize.height + footer.frame.height + separator.frame.height
        tableView.isScrollEnabled = contentHeight > maxHeight
        return min(maxHeight, contentHeight)
    }
    
    // MARK: - Init
    
    init(event: BetEventViewModel, wm: BTCWalletManager, sender: BitcoinSender, didChangeLegs: @escaping (()-> Void)) {
        self.event = event
        self.viewModel = event
        self.walletManager = wm
        self.sender = sender
        self.didChangeLegs = didChangeLegs
        self.parlayBet = wm.parlayBet
        //self.header = ModalHeaderView(title: "", style: .transaction, faqInfo: ArticleIds.betSlip, currency: event.currency)
        
        super.init(nibName: nil, bundle: nil)
        /*
        header.closeCallback = { [weak self] in
            self?.close()
        }
         */
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = EventDetailDataSource(tableView: tableView, viewModel: viewModel, controller: self, didTapBetsmart: didTapBetsmart)

        setup()
        
        registerForKeyboardNotifications()
        
        // refresh if rate changes
        Store.lazySubscribe(self, selector: { $0[self.viewModel.currency]?.currentRate != $1[self.viewModel.currency]?.currentRate }, callback: { _ in self.reload() })
        // refresh if tx state changes
        Store.lazySubscribe(self, selector: {
            guard let oldEvents = $0[self.viewModel.currency]?.events else { return false }
            guard let newEvents = $1[self.viewModel.currency]?.events else { return false }
            return oldEvents != newEvents }, callback: { [unowned self] in
            guard let event = $0[self.viewModel.currency]?.events.first(where: { $0.eventID == self.viewModel.eventID }) else {
                // close slip
                self.close()
                return }
            self.event = event
        })
    }
    
    // bet option cell delegate
    func didTapBetOption(choice: EventBetChoice, isSelected: Bool) {
        let sliderPos = (dataSource?.prepareBetLayout(choice: choice))!
        let sliderIndexPath = IndexPath(row: sliderPos, section: 0)
        tableView.beginUpdates()
        if sliderPosToRemove == 0  {
            tableView.insertRows(at: [sliderIndexPath], with: .automatic)
            sliderPosToRemove = sliderPos
        }
        else    {
            if sliderPosToRemove != sliderPos   {
                if isSelected   {
                    tableView.moveRow(at: IndexPath(row: sliderPosToRemove, section: 0), to: IndexPath(row: sliderPos, section: 0))
                    sliderPosToRemove = sliderPos
                }
                else {
                    tableView.deleteRows(at: [sliderIndexPath], with: .none)
                    sliderPosToRemove = 0
                }
            }
            else    {
                if !isSelected  { didTapCancel() }
            }
        }
        tableView.endUpdates()
        if isSelected {
            tableView.scrollToRow(at: sliderIndexPath, at: .bottom, animated: true)
        }
        
        dataSource?.registerBetChoice(choice: choice)
        updateLegButton( choice: choice )
    }
    
    func updateLegButton( choice: EventBetChoice )  {
        switch (walletManager.parlayBet.checkBetInParlay(eventID: viewModel.eventID, outcome: choice.getOutcome()))  {
            case .OUTCOME_IN_LEG:
                dataSource?.updateLegButton(mode: .remove)
            
            case .EVENT_IN_LEG:
                dataSource?.updateLegButton(mode: .hidden)
            
            case .NOT_IN_LEG:
                if walletManager.parlayBet.legCount == W.Parlay.maxLegs   {
                    dataSource?.updateLegButton(mode: .hidden)
                }
                else    {
                    dataSource?.updateLegButton(mode: .add)
                }
        }
    }
    
    // MARK: bet slider cell delegates
    func didTapOk(choice: EventBetChoice, amount: Int) {
        // check event timestamp
        let now = Date()
        if viewModel.eventTimestamp - now.timeIntervalSinceReferenceDate < W.Blockchain.cutoffSeconds    {
            let alert = UIAlertController(title: S.Alert.error, message: S.Betting.errorTimeout, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: S.Button.ok, style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else    {
            let cryptoAmount = UInt256(UInt64(amount)*C.satoshis)
            let transaction = walletManager.wallet?.createBetTransaction(forAmount: (UInt64(amount)*C.satoshis), type: BetType.PEERLESS.rawValue, eventID: Int32(viewModel.eventID), outcome: choice.getOutcome().rawValue)

            self.sender.setBetTransaction(tx: transaction)
            
            let fee = sender.fee(forAmount: cryptoAmount) ?? UInt256(0)
            let feeCurrency = Currencies.btc
            let currency = Currencies.btc
            
            let displyAmount = Amount(amount: cryptoAmount,
                                      currency: currency,
                                      rate: currency.state?.currentRate,
                                      maximumFractionDigits: Amount.highPrecisionDigits)
            let feeAmount = Amount(amount: fee,
                                   currency: feeCurrency,
                                   rate: (currency.state?.currentRate != nil) ? feeCurrency.state?.currentRate : nil,
                                   maximumFractionDigits: Amount.highPrecisionDigits)

            let confirm = ConfirmationViewController(amount: Amount(amount: cryptoAmount, currency: currency),
                                                     fee: feeAmount,
                                                     feeType: .regular,
                                                     address: "Event contract",
                                                     isUsingBiometrics: sender.canUseBiometrics,
                                                     currency: currency)
            confirm.successCallback = doSend
            confirm.cancelCallback = sender.reset
            
            confirmTransitioningDelegate.shouldShowMaskView = false
            confirm.transitioningDelegate = confirmTransitioningDelegate
            confirm.modalPresentationStyle = .overFullScreen
            confirm.modalPresentationCapturesStatusBarAppearance = true
            present(confirm, animated: true, completion: nil)
        }
        
    }
       
    func didTapCancel() {
        dataSource?.prepareBetLayout(choice: nil)
        tableView.beginUpdates()
        tableView.deleteRows(at: [IndexPath(row: sliderPosToRemove, section: 0)], with: .none)
        tableView.endUpdates()
        sliderPosToRemove = 0
        let choice = EventBetChoice.init(option: .none, type: .none, odd: 1.0, effectiveOdd: 0 )
        dataSource?.cleanBetOptions( choice: choice )
    }

    func didTapAddLeg(choice: EventBetChoice)   {
        let leg = ParlayLegEntity.init(event: viewModel, outcome: choice.getOutcome(), odd: UInt32(0))
        leg.updateOdd()
        if walletManager.parlayBet.add(leg: leg)    {
            didChangeLegsBetSlip()
        }
        else {
            if walletManager.parlayBet.legCount == W.Parlay.maxLegs   {
                self.showAlert(title: S.Alert.error, message: String.init(format: S.ParlayDetails.maxLegs, W.Parlay.maxLegs), buttonLabel: S.Button.ok)
            }
            else    {
                self.showAlert(title: S.Alert.error, message: S.EventDetails.addLegError, buttonLabel: S.Button.ok)
            }
        }
    }
    
    func didTapRemoveLeg(choice: EventBetChoice)    {
        walletManager.parlayBet.removeByEventID(eventID: viewModel.eventID)
        didChangeLegsBetSlip()
    }
    
    // MARK: other tap events
    func didTapBetsmart(teamName : String)   {
        var style = "light"
        if #available(iOS 13.0, *) {
            if UIScreen.main.traitCollection.userInterfaceStyle == .dark    {
                style="dark"
            }
        }
        
        let betsmartDetails = WebViewController(theURL: String.init(format: "https://betsmart.app/teaser-team/?name=%@&sport=%@&mode=%@&source=wagerr"
            , teamName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                                                                    , viewModel.txSport.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, style), didClose: {})
        betsmartDetails.modalPresentationStyle = .overCurrentContext
        //betsmartDetails.transitioningDelegate = transitionDelegate
        betsmartDetails.modalPresentationCapturesStatusBarAppearance = true
        present(betsmartDetails, animated: true, completion: nil)
    }
    
    func doSend()   {
        let pinVerifier: PinVerifier = { [weak self] pinValidationCallback in
            self?.presentVerifyPin?(S.VerifyPin.authorize) { pin in
                self?.parent?.view.isFrameChangeBlocked = false
                pinValidationCallback(pin)
            }
        }
        
        sender.sendTransaction(allowBiometrics: true, pinVerifier: pinVerifier) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success:
                self.dismiss(animated: true, completion: {
                    Store.trigger(name: .showStatusBar)
                    self.onPublishSuccess?()
                })
                self.saveEvent("send.success")
            case .creationError(let message):
                self.showAlert(title: S.Send.createTransactionError, message: message, buttonLabel: S.Button.ok)
                self.saveEvent("send.publishFailed", attributes: ["errorMessage": message])
            case .publishFailure(let error):
                if case .posixError(let code, let description) = error {
                    self.showAlert(title: S.Alerts.sendFailure, message: "\(description) (\(code))", buttonLabel: S.Button.ok)
                    self.saveEvent("send.publishFailed", attributes: ["errorMessage": "\(description) (\(code))"])
                }
            case .insufficientGas(let rpcErrorMessage):
                self.saveEvent("send.publishFailed", attributes: ["errorMessage": rpcErrorMessage])
            }
        }
    }
    
    private func setup() {
        addSubViews()
        addConstraints()
        //setupActions()
        setInitialData()
    }
    
    private func addSubViews() {
        //view.addSubview(tapView)
        //view.addSubview(container)
        //view.addSubview(header)
        view.addSubview(tableView)
        view.addSubview(footer)
        view.addSubview(separator)
        view.addSubview(parlayOpenButton)
    }
    
    private func addConstraints() {
        /*
        tapView.constrain(toSuperviewEdges: nil)
        container.constrain([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        
        containerHeightConstraint = container.heightAnchor.constraint(equalToConstant: compactContainerHeight)
        containerHeightConstraint.isActive = true
        */
        //header.constrainTopCorners(height: C.Sizes.headerHeight)
        
        tableView.constrain([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: footer.topAnchor)
            ])
        
        footer.constrainBottomCorners(height: C.detailsButtonHeight)
        separator.constrain([
            separator.leadingAnchor.constraint(equalTo: footer.leadingAnchor),
            separator.topAnchor.constraint(equalTo: footer.topAnchor, constant: 1.0),
            separator.trailingAnchor.constraint(equalTo: footer.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5) ])
        
        parlayOpenButton.translatesAutoresizingMaskIntoConstraints = false
        parlayOpenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor , constant: -10).isActive = true
        parlayOpenButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        parlayOpenButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        parlayOpenButton.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
        parlayOpenButton.isHidden = (parlayBet?.legCount == 0) ? true : false
    }
    
    private func setupActions() {
        let gr = UITapGestureRecognizer(target: self, action: #selector(close))
        tapView.addGestureRecognizer(gr)
        tapView.isUserInteractionEnabled = true
    }
    
    private func setInitialData() {
        /*
        container.layer.cornerRadius = C.Sizes.roundedCornerRadius
        container.layer.masksToBounds = true
        */
        footer.backgroundColor = .whiteBackground
        separator.backgroundColor = .secondaryShadow
        
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 65.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.allowsSelection = false
        tableView.isScrollEnabled = false
        tableView.showsVerticalScrollIndicator = false
        
        dataSource?.registerCells(forTableView: tableView)
        
        tableView.dataSource = dataSource
        tableView.reloadData()
        
        parlayOpenButton.setTitle( String.init(parlayBet!.legCount) , for: .normal)
        parlayOpenButton.titleLabel!.font = UIFont.customBold(size: 22.0)
        parlayOpenButton.frame.size = CGSize(width: 44, height: 44)
        parlayOpenButton.backgroundColor = .systemOrange
        parlayOpenButton.clipsToBounds = true
        parlayOpenButton.layer.cornerRadius = 24
        parlayOpenButton.layer.borderWidth = 0.0
        
        let tapActionOpenParlay = UITapGestureRecognizer(target: self, action:#selector(self.actionTappedOpenParlay(tapGestureRecognizer:)))
        parlayOpenButton.isUserInteractionEnabled = true
        parlayOpenButton.addGestureRecognizer(tapActionOpenParlay)
    }
        
    @objc func actionTappedOpenParlay(tapGestureRecognizer: UITapGestureRecognizer) {
        Store.perform(action: RootModalActions.Present(modal: .sendparlay(parlay: (walletManager as! BTCWalletManager).parlayBet, didChangeLegs: didChangeLegsBetSlip) ))
    }
    
    private func didChangeLegsBetSlip()    {
        if parlayBet?.legCount == 0 {
            parlayOpenButton.isHidden = true
        }
        else    {
            parlayOpenButton.isHidden = false
            parlayOpenButton.setTitle( String.init(parlayBet!.legCount) , for: .normal)
        }
        // refresh parlay button
        if ( dataSource?.currChoice != nil)     {
            updateLegButton(choice: dataSource!.currChoice! )
        }
        
        // bubble up
        didChangeLegs()
    }
    
    private func reload() {
        viewModel = event
        let currChoice = (self.dataSource as! EventDetailDataSource).currChoice
        self.dataSource = EventDetailDataSource(tableView: tableView, viewModel: viewModel, controller: self, didTapBetsmart: didTapBetsmart )
        dataSource?.prepareBetLayout(choice: currChoice)
        tableView.dataSource = dataSource
        tableView.reloadData()
    }
    
    deinit {
        Store.unsubscribe(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    
    @objc private func close() {
        if let delegate = transitioningDelegate as? ModalTransitionDelegate {
            delegate.reset()
        }
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - Keyboard Handler
extension EventDetailViewController {
    fileprivate func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc fileprivate func keyboardWillShow(notification: NSNotification) {
        if let delegate = transitioningDelegate as? ModalTransitionDelegate {
            delegate.shouldDismissInteractively = false
        }
        /*
        if let keyboardHeight = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0)
        }
        */
        //Need to calculate keyboard exact size due to Apple suggestions
        self.tableView.isScrollEnabled = true
        var offset = CGFloat(0)
        if #available(iOS 11.0, *)   {
            if E.isIPhoneXOrBetter  {
                offset = view.safeAreaInsets.bottom
            }
        }
        let info : NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height + offset, 0.0)

        self.tableView.contentInset = contentInsets
        self.tableView.scrollIndicatorInsets = contentInsets

        DispatchQueue.main.async {
            let sliderIndexPath = IndexPath(row: self.sliderPosToRemove, section: 0)
            if let _ = self.tableView.cellForRow(at: sliderIndexPath) {
                self.tableView.scrollToRow(at: sliderIndexPath, at: .bottom, animated: true)
            }
        }
        
/*
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height + offset
        if let activeFrame = self.dataSource?.sliderCell?.amountTextFrame
        {
            if (!aRect.contains(activeFrame.origin))
            {
                DispatchQueue.main.async {
                    self.tableView.scrollRectToVisible(activeFrame, animated: true)
                }
            }
        }
 */
    }
    
    @objc fileprivate func keyboardWillHide(notification: NSNotification) {
        if let delegate = transitioningDelegate as? ModalTransitionDelegate {
            delegate.shouldDismissInteractively = true
        }
        UIView.animate(withDuration: 0.2, animations: {
            // adding inset in keyboardWillShow is animated by itself but removing is not
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        })
    }
    
    func deregisterFromKeyboardNotifications()
    {
        //Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
}

//MARK: - Wagerr Explorer Navigation functions
enum EventExplorerType {
    case address
    case event
    case transaction
}

extension EventDetailViewController {

    static func navigate(to: String, type: EventExplorerType) {
        let baseURL = (E.isTestnet) ? "https://explorer2.wagerr.com/#" : "https://explorer.wagerr.com/#"
        var typeURL = ""
        switch type {
            case .address:
                typeURL = "address"
            case .event:
                typeURL = "bet/event"
            case .transaction:
                typeURL = "tx"
        }
        guard let url = URL(string: String.init(format: "%@/%@/%@", baseURL, typeURL, to)) else {
            return //be safe
        }

        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}

extension EventDetailViewController : ModalDisplayable {
    var faqArticleId: String? {
        return ArticleIds.betSlip
    }
    
    var faqCurrency: CurrencyDef? {
        return Currencies.btc
    }

    var modalTitle: String {
        return ""
    }
}

