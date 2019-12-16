//
//  EventDetailRowCell.swift
//  breadwallet
//
//  Created by MIP
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import UIKit

class EventBetLabel : UILabel   {
    
    var textInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10) {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = UIEdgeInsetsInsetRect(bounds, textInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textInsets.top,
                                          left: -textInsets.left,
                                          bottom: -textInsets.bottom,
                                          right: -textInsets.right)
        return UIEdgeInsetsInsetRect(textRect, invertedInsets)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, textInsets))
    }
    
    func toggleLabel() -> Bool  {
        var bRet = false
        if self.font.pointSize == W.FontSize.normalSize    {
           self.font = self.font.withSize(W.FontSize.selectSize)
           bRet = true
        }
        else {
           self.font = self.font.withSize(W.FontSize.normalSize)
           bRet = false
        }
        return bRet
    }
}

class EventDetailRowCell: UITableViewCell {
    
    var rowHeight = CGFloat(34.0)
    
    // MARK: - Accessors
    
    public var title: String {
        get {
            return titleLabel.text ?? ""
        }
        set {
            titleLabel.text = newValue
        }
    }

    // MARK: - Views
    
    internal let container = UIView()
    internal let titleLabel = UILabel(font: UIFont.customBody(size: 14.0))
    //internal let separator = UIView(color: .secondaryShadow)
    
    // MARK: - Init
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    private func setupViews() {
        addSubviews()
        addConstraints()
        setupStyle()
    }
    
    internal func addSubviews() {
        contentView.addSubview(container)
        //contentView.addSubview(separator)
        container.addSubview(titleLabel)
    }
    
    func addContraintMain()    {
        container.constrain(toSuperviewEdges: UIEdgeInsets(top: C.padding[1],
                                                           left: C.padding[2],
                                                           bottom: -C.padding[1],
                                                           right: -C.padding[2]))
        container.constrain([container.heightAnchor.constraint(greaterThanOrEqualToConstant: rowHeight)])
    }
    
    func addContraintLabel()   {
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.constrain([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.constraint(toTop: container, constant: C.padding[3])
            ])
        //separator.constrainTopCorners(height: 0.5)
    }
    
    internal func addConstraints() {
        self.addContraintMain()
        self.addContraintLabel()
    }
    
    internal func setupStyle() {
        titleLabel.textColor = .primaryText
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
