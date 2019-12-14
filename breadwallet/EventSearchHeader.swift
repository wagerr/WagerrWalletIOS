//
//  EventSearchHeader.swift
//  breadwallet
//
//  Created by MIP on 24/11/2019.
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit

enum EventSearchFilterType {

    case sport(Int)
    case tournament(Int)
    case text(String)

    var description: String {
        switch self {
        case .sport(_):
            return "Sport"
        case .tournament(_):
            return "Tournament"
        case .text(_):
            return ""
        }
    }

    var filter: EventFilter {
        switch self {
        case .sport(let sportID):
            return { $0.sportID == sportID || sportID == -1 }
        case .tournament(let tournamentID):
            return { $0.tournamentID == tournamentID || tournamentID == -1 }
        case .text(let text):
            return { event in
                let loweredText = text.lowercased()
                if event.txHash.lowercased().contains(loweredText) {
                    return true
                }
                if String(event.eventID).lowercased().contains(loweredText) {
                    return true
                }
                if event.txSport.lowercased().contains(loweredText) {
                    return true
                }
                if event.txTournament.lowercased().contains(loweredText) {
                    return true
                }
                if event.txRound.lowercased().contains(loweredText) {
                    return true
                }
                if event.txHomeTeam.lowercased().contains(loweredText) {
                    return true
                }
                if event.txAwayTeam.lowercased().contains(loweredText) {
                    return true
                }
                return false
            }
        }
    }
}

extension EventSearchFilterType : Equatable {}

func ==(lhs: EventSearchFilterType, rhs: EventSearchFilterType) -> Bool {
    switch (lhs, rhs) {
        case (.sport(_), .sport(_)):
            return true
        case (.tournament(_), .tournament(_)):
            return true
        case (.text(_), .text(_)):
            return true
        default:
            return false
    }
}

typealias EventFilter = (BetEventViewModel) -> Bool

class EventSearchHeaderView : UIView {

    init() {
        super.init(frame: .zero)
    }

    var didCancel: (() -> Void)?
    var didChangeFilters: (([EventFilter]) -> Void)?
    var hasSetup = false

    func triggerUpdate() {
        didChangeFilters?(filters.map { $0.filter })
    }

    private let searchBar = UISearchBar()
    private let cancel = UIButton(type: .system)
    fileprivate var filters: [EventSearchFilterType] = [] {
        didSet {
            didChangeFilters?(filters.map { $0.filter })
        }
    }

    override func layoutSubviews() {
        guard !hasSetup else { return }
        setup()
        hasSetup = true
    }

    private func setup() {
        addSubviews()
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
            searchBar.topAnchor.constraint(equalTo: topAnchor, constant: E.isIPhoneX ? C.padding[5] : C.padding[2]),
            searchBar.trailingAnchor.constraint(equalTo: cancel.leadingAnchor, constant: -C.padding[1]) ])
    }

    private func setData() {
        backgroundColor = .whiteTint
        searchBar.backgroundImage = UIImage()
        searchBar.delegate = self
        cancel.tap = { [weak self] in
            self?.didChangeFilters?([])
            self?.searchBar.resignFirstResponder()
            self?.didCancel?()
        }
    }
    
    @discardableResult private func toggleFilterType(_ filterType: EventSearchFilterType) -> Bool {
        if let index = filters.index(of: filterType) {
            filters.remove(at: index)
            return false
        } else {
            filters.append(filterType)
            return true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EventSearchHeaderView : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let filter: EventSearchFilterType = .text(searchText)
        if let index = filters.index(of: filter) {
            filters.remove(at: index)
        }
        if searchText != "" {
            filters.append(filter)
        }
    }
}

