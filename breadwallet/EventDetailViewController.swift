//
//  EventDetailViewController.swift
//  breadwallet
//
//  Created by MIP on 24/11/2019.
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit

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

class EventDetailViewController: UIViewController, Subscriber, EventBetOptionDelegate, EventBetSliderDelegate {
        
    // MARK: - Private Vars
    
    private let container = UIView()
    private let tapView = UIView()
    private let header: ModalHeaderView
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
    private var dataSource: EventDetailDataSource?
    private var isExpanded: Bool = true
    
    private var compactContainerHeight: CGFloat {
        return C.expandedContainerHeight
    }
    
    private var expandedContainerHeight: CGFloat {
        let maxHeight = view.frame.height - C.padding[4]
        var contentHeight = header.frame.height + tableView.contentSize.height + footer.frame.height + separator.frame.height
        tableView.isScrollEnabled = contentHeight > maxHeight
        return min(maxHeight, contentHeight)
    }
    
    // MARK: - Init
    
    init(event: BetEventViewModel) {
        self.event = event
        self.viewModel = event
        self.header = ModalHeaderView(title: "", style: .transaction, faqInfo: ArticleIds.betSlip, currency: event.currency)
        
        super.init(nibName: nil, bundle: nil)
        self.dataSource = EventDetailDataSource(viewModel: viewModel, controller: self)
        
        header.closeCallback = { [weak self] in
            self?.close()
        }
        
        setup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForKeyboardNotifications()
        
        // refresh if rate changes
        Store.lazySubscribe(self, selector: { $0[self.viewModel.currency]?.currentRate != $1[self.viewModel.currency]?.currentRate }, callback: { _ in self.reload() })
        // refresh if tx state changes
        Store.lazySubscribe(self, selector: {
            guard let oldTransactions = $0[self.viewModel.currency]?.transactions else { return false }
            guard let newTransactions = $1[self.viewModel.currency]?.transactions else { return false }
            return oldTransactions != newTransactions }, callback: { [unowned self] in
            guard let event = $0[self.viewModel.currency]?.events.first(where: { $0.eventID == self.viewModel.eventID }) else { return }
            self.event = event
        })
    }
    
    // bet option cell delegate
    func didTapBetOption(choice: EventBetChoice, isSelected: Bool) {
        let sliderPos = (dataSource?.prepareBetLayout(choice: choice))!
        tableView.beginUpdates()
        if sliderPosToRemove == 0  {
            tableView.insertRows(at: [IndexPath(row: sliderPos, section: 0)], with: .automatic)
            sliderPosToRemove = sliderPos
        }
        else    {
            if sliderPosToRemove != sliderPos   {
                if isSelected   {
                    tableView.moveRow(at: IndexPath(row: sliderPosToRemove, section: 0), to: IndexPath(row: sliderPos, section: 0))
                    sliderPosToRemove = sliderPos
                }
                else {
                    tableView.deleteRows(at: [IndexPath(row: sliderPos, section: 0)], with: .none)
                    sliderPosToRemove = 0
                }
            }
            else    {
                if !isSelected  { didTapCancel() }
            }
        }
        tableView.endUpdates()
        dataSource?.registerBetChoice(choice: choice)
    }
    
    // bet slider cell delegates
    func didTapOk(choice: EventBetChoice, amount: Int) {
        print("tapOk")
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
        setupActions()
        setInitialData()
    }
    
    private func addSubViews() {
        view.addSubview(tapView)
        view.addSubview(container)
        container.addSubview(header)
        container.addSubview(tableView)
        container.addSubview(footer)
        container.addSubview(separator)
    }
    
    private func addConstraints() {
        tapView.constrain(toSuperviewEdges: nil)
        container.constrain([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        
        containerHeightConstraint = container.heightAnchor.constraint(equalToConstant: compactContainerHeight)
        containerHeightConstraint.isActive = true
        
        header.constrainTopCorners(height: C.Sizes.headerHeight)
        tableView.constrain([
            tableView.topAnchor.constraint(equalTo: header.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
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
        container.layer.cornerRadius = C.Sizes.roundedCornerRadius
        container.layer.masksToBounds = true
        
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
        
        header.setTitle(viewModel.title)
    }
    
    private func reload() {
        viewModel = event
        //dataSource = EventDetailDataSource(viewModel: viewModel)
        //tableView.dataSource = dataSource
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
        if let keyboardHeight = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0)
        }
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
