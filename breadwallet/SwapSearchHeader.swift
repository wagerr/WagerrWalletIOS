//
//  SwapSearchHeader.swift
//  Wagerr Pro
//
//  Created by MIP on 06/02/2020.
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit

enum SwapSearchFilterType {
    case open
    case notcompleted
    case completed
    case text(String)

    var description: String {
        switch self {
        case .open:
            return S.Instaswap.open
        case .notcompleted:
            return S.Instaswap.notcompleted
        case .completed:
            return S.Instaswap.completed
        case .text(_):
            return ""
        }
    }

    var filter: SwapFilter {
        switch self {
        case .open:
            return { $0.response.transactionState != .completed && $0.response.transactionState != .notcompleted }
        case .notcompleted:
            return { $0.response.transactionState == .notcompleted }
        case .completed:
            return { $0.response.transactionState == .completed }
        case .text(let text):
            return { swapInfo in
                let loweredText = text.lowercased()
                if swapInfo.response.transactionId.lowercased().contains(loweredText) {
                    return true
                }
                return false
            }
        }
    }
}

extension SwapSearchFilterType : Equatable {}

func ==(lhs: SwapSearchFilterType, rhs: SwapSearchFilterType) -> Bool {
    switch (lhs, rhs) {
    case (.open, .open):
        return true
    case (.completed, .completed):
        return true
    case (.notcompleted, .notcompleted):
        return true
    case (.text(_), .text(_)):
        return true
    default:
        return false
    }
}

typealias SwapFilter = (SwapViewModel) -> Bool

class SwapSearchHeaderView : UIView {

    init() {
        super.init(frame: .zero)
    }

    var didCancel: (() -> Void)?
    var didChangeFilters: (([SwapFilter]) -> Void)?
    var hasSetup = false

    func triggerUpdate() {
        didChangeFilters?(filters.map { $0.filter })
    }

    private let searchBar = UISearchBar()
    private let open = ShadowButton(title: S.Instaswap.open, type: .search, YCompressionFactor: 2.0)
    private let notcompleted = ShadowButton(title: S.Instaswap.notcompleted, type: .search, YCompressionFactor: 2.0)
    private let completed = ShadowButton(title: S.Instaswap.completed, type: .search, YCompressionFactor: 2.0)
    
    private let cancel = UIButton(type: .system)
    fileprivate var filters: [SwapSearchFilterType] = [] {
        didSet {
            didChangeFilters?(filters.map { $0.filter })
        }
    }

    private let openFilter: SwapFilter = { return $0.response.transactionState != .completed && $0.response.transactionState != .notcompleted }
    private let notcompletedFilter: SwapFilter = { return $0.response.transactionState == .notcompleted }
    private let completedFilter: SwapFilter = { return $0.response.transactionState == .completed }

    override func layoutSubviews() {
        guard !hasSetup else { return }
        setup()
        hasSetup = true
    }

    private func setup() {
        addSubviews()
        addFilterButtons()
        addConstraints()
        setData()
    }

    private func addSubviews() {
        addSubview(searchBar)
        addSubview(cancel)
    }

    private func addConstraints() {
        cancel.setTitle(S.Button.cancel, for: .normal)
        let titleSize = NSString(string: cancel.titleLabel!.text!).size(withAttributes: [NSAttributedStringKey.font : cancel.titleLabel!.font])
        cancel.constrain([
            cancel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            cancel.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            cancel.widthAnchor.constraint(equalToConstant: titleSize.width + C.padding[4])])
        searchBar.constrain([
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[1]),
            searchBar.topAnchor.constraint(equalTo: topAnchor, constant: E.isIPhoneXOrBetter ? C.padding[4] : C.padding[2]),
            searchBar.trailingAnchor.constraint(equalTo: cancel.leadingAnchor, constant: -C.padding[1]) ])
    }

    private func setData() {
        backgroundColor = .grayBackground
        searchBar.backgroundImage = UIImage()
        searchBar.delegate = self
        cancel.tap = { [weak self] in
            self?.didChangeFilters?([])
            self?.searchBar.resignFirstResponder()
            self?.didCancel?()
        }
        open.isToggleable = true
        notcompleted.isToggleable = true
        completed.isToggleable = true

        open.tap = { [weak self] in
            guard let myself = self else { return }
            if myself.toggleFilterType(.open) {
                if myself.notcompleted.isSelected {
                    myself.notcompleted.isSelected = false
                    myself.toggleFilterType(.notcompleted)
                }
                if myself.completed.isSelected {
                    myself.completed.isSelected = false
                    myself.toggleFilterType(.completed)
                }
            }
        }

        notcompleted.tap = { [weak self] in
            guard let myself = self else { return }
            if myself.toggleFilterType(.notcompleted) {
                if myself.open.isSelected {
                    myself.open.isSelected = false
                    myself.toggleFilterType(.open)
                }
                if myself.completed.isSelected {
                    myself.completed.isSelected = false
                    myself.toggleFilterType(.completed)
                }
            }
        }

        completed.tap = { [weak self] in
            guard let myself = self else { return }
            if myself.toggleFilterType(.completed) {
                if myself.open.isSelected {
                    myself.open.isSelected = false
                    myself.toggleFilterType(.open)
                }
                if myself.notcompleted.isSelected {
                    myself.notcompleted.isSelected = false
                    myself.toggleFilterType(.notcompleted)
                }
            }
        }
    }

    @discardableResult private func toggleFilterType(_ filterType: SwapSearchFilterType) -> Bool {
        if let index = filters.index(of: filterType) {
            filters.remove(at: index)
            return false
        } else {
            filters.append(filterType)
            return true
        }
    }

    private func addFilterButtons() {
        /* if #available(iOS 9, *) {
            let stackView = UIStackView()
            addSubview(stackView)
            stackView.distribution = .fillProportionally
            stackView.spacing = C.padding[1]
            stackView.constrain([
                stackView.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor),
                stackView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: C.padding[1]),
                stackView.trailingAnchor.constraint(equalTo: cancel.trailingAnchor) ])
            stackView.addArrangedSubview(sent)
            stackView.addArrangedSubview(received)
            stackView.addArrangedSubview(pending)
            stackView.addArrangedSubview(complete)
            stackView.addArrangedSubview(bethistory)
            stackView.addArrangedSubview(payout)
        } else {
            */
            addSubview(open)
            addSubview(notcompleted)
            addSubview(completed)
            open.constrain([
                open.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: C.padding[2]),
                open.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: C.padding[4]) ])
            notcompleted.constrain([
                notcompleted.leadingAnchor.constraint(equalTo: open.trailingAnchor, constant: C.padding[1]),
                notcompleted.topAnchor.constraint(equalTo: open.topAnchor)])
            completed.constrain([
                completed.leadingAnchor.constraint(equalTo: notcompleted.trailingAnchor, constant: C.padding[1]),
                completed.topAnchor.constraint(equalTo: notcompleted.topAnchor)])
        //}
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SwapSearchHeaderView : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let filter: SwapSearchFilterType = .text(searchText)
        if let index = filters.index(of: filter) {
            filters.remove(at: index)
        }
        if searchText != "" {
            filters.append(filter)
        }
    }
}
