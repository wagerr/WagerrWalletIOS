//
//  TOSCell.swift
//  breadwallet
//
//  Created by MIP on 2020-03-04.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit

class TOSCell : UIView {

    init() {
        super.init(frame: .zero)
        setupViews()
    }


    func setContent(_ content: String?) {
        contentLabel.text = content
    }

    func setLabel(_ content: String?) {
        linkLabel.text = content
    }

    fileprivate let contentLabel = UILabel(font: .customBody(size: 14.0), color: .darkText)
    private let linkLabel = UILabel(font: .customBody(size: 14.0))
    private let switchAccept = UISwitch(frame: CGRect(x: 163, y: 150, width: 0, height: 0))
    var didTapAccept : ((Bool)->Void)?

    private func setupViews() {
        addSubviews()
        addConstraints()
        setInitialData()
    }

    private func addSubviews() {
        addSubview(contentLabel)
        addSubview(linkLabel)
        addSubview(switchAccept)
    }

    private func addConstraints() {
        contentLabel.constrain([
            contentLabel.constraint(.centerY, toView: self),
            contentLabel.constraint(.leading, toView: self, constant: C.padding[2]) ])
        linkLabel.constrain([
            linkLabel.topAnchor.constraint( equalTo: contentLabel.topAnchor, constant: 0.0),
            linkLabel.leadingAnchor.constraint( equalTo: contentLabel.trailingAnchor, constant: 0.0) ])
        switchAccept.constrain([
            switchAccept.topAnchor.constraint(equalTo: contentLabel.topAnchor, constant: 0.0),
            switchAccept.leadingAnchor.constraint( equalTo: linkLabel.trailingAnchor, constant: C.padding[2])])
    }

    private func setInitialData() {
        contentLabel.text = S.Instaswap.TOScontent
        contentLabel.textColor = .darkText
        //linkLabel.text = S.Instaswap.TOSlink

        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: S.Instaswap.TOSlink)
        attributeString.addAttribute(NSAttributedStringKey.underlineStyle, value: 1, range: NSMakeRange(0, attributeString.length))
        linkLabel.attributedText = attributeString
        linkLabel.textColor = .systemBlue
        
        let gr = UITapGestureRecognizer(target: self, action: #selector(didTap))
        linkLabel.addGestureRecognizer(gr)
        linkLabel.isUserInteractionEnabled = true
    
        switchAccept.tap = strongify(self) { myself in
            self.didTapAccept?(self.switchAccept.isOn)
        }
    }

    @objc private func didTap() {
        guard let url = URL(string: "https://wagerr.zendesk.com/hc/en-us/articles/360040437891") else {
            return //be safe
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
