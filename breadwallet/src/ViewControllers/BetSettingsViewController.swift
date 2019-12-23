//
//  NodeSelectorViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-08-03.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit
import BRCore

class BetSettingsViewController : UIViewController {

    var delegate : BetSettingsDelegate? = nil
    let titleLabel = UILabel(font: .customBold(size: 24.0), color: .darkText)
    private let checkIncludeFee = UIButton(type: .system)
    private let labelIncludeFee = UIButton()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    var isChecked: Bool = false {
        didSet {
            checkIncludeFee.tintColor = isChecked ? .primaryButton : .grayTextTint
        }
    }
    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        setInitialData()
    }

    private func addSubviews() {
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "< Back", style: UIBarButtonItemStyle.bordered, target: self, action: #selector(self.back(sender:)))
        newBackButton.tintColor = .primaryText
        self.navigationItem.leftBarButtonItem = newBackButton
        
        view.addSubview(titleLabel)
        view.addSubview(checkIncludeFee)
        view.addSubview(labelIncludeFee)
    }

    @objc func back(sender: UIBarButtonItem) {
        delegate?.didTapBetSettingsBack()
        self.navigationController?.popViewController(animated: true)
    }
    
    private func addConstraints() {
        var padding = C.padding[2]
        if delegate != nil {
            padding = C.padding[10]
        }
        titleLabel.constrain([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2])
            ])
        
        checkIncludeFee.constrain([
            checkIncludeFee.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: C.padding[2]),
            checkIncludeFee.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[4]),
        ])
        
        labelIncludeFee.constrain([
            labelIncludeFee.topAnchor.constraint(equalTo: checkIncludeFee.topAnchor, constant: -C.padding[1]/2 ),
            labelIncludeFee.leadingAnchor.constraint(equalTo: checkIncludeFee.trailingAnchor, constant: C.padding[2]),
        ])
    }

    private func setInitialData() {
        view.backgroundColor = .whiteBackground
        titleLabel.text = S.BetSettings.headerMessage
        titleLabel.textAlignment = .right
        labelIncludeFee.setTitle(S.BetSettings.useFeeCheck, for: .normal)
        labelIncludeFee.setTitleColor(.primaryText, for: .normal)
        labelIncludeFee.titleLabel?.font = UIFont.customBody(size: 14.0)
        labelIncludeFee.tap = strongify(self) { myself in
            self.isChecked = !self.isChecked
            UserDefaults.showNetworkFeesInOdds = self.isChecked
        }
        
        checkIncludeFee.setImage(#imageLiteral(resourceName: "CircleCheck"), for: .normal)
        self.isChecked = UserDefaults.showNetworkFeesInOdds
        checkIncludeFee.tap = labelIncludeFee.tap
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
