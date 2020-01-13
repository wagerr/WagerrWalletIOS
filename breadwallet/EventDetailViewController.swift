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
}

class EventDetailViewController: UIViewController, Subscriber, EventBetOptionDelegate, EventBetSliderDelegate, Trackable {
       
    // MARK: - Private Vars
    
    private let container = UIView()
    private let tapView = UIView()
    //private let header: ModalHeaderView
    private let footer = UIView()
    private let separator = UIView()
    private let tableView = UITableView()
    
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
    
    init(event: BetEventViewModel, wm: BTCWalletManager, sender: BitcoinSender) {
        self.event = event
        self.viewModel = event
        self.walletManager = wm
        self.sender = sender
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
        self.dataSource = EventDetailDataSource(tableView: tableView, viewModel: viewModel, controller: self)

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
    }
    
    // bet slider cell delegates
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
                                                     address: "Betting",
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
    
    func didTapCancel() {
        dataSource?.prepareBetLayout(choice: nil)
        tableView.beginUpdates()
        tableView.deleteRows(at: [IndexPath(row: sliderPosToRemove, section: 0)], with: .none)
        tableView.endUpdates()
        sliderPosToRemove = 0
        let choice = EventBetChoice.init(option: .none, type: .none, odd: 1.0 )
        dataSource?.cleanBetOptions( choice: choice )
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
        
        //header.setTitle(viewModel.title)
    }
    
    private func reload() {
        viewModel = event
        self.dataSource = EventDetailDataSource(tableView: tableView, viewModel: viewModel, controller: self)
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
        let baseURL = "https://explorer.wagerr.com/#"
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

