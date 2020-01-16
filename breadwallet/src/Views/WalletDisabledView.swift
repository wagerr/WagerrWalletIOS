//
//  WalletDisabledView.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-05-01.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit

class WalletDisabledView : UIView {

    func setTimeLabel(string: String) {
        label.text = string
    }

    init() {
        self.faq = UIButton.buildFaqButton(articleId: ArticleIds.walletDisabled)
        blur = UIVisualEffectView()
        super.init(frame: .zero)
        setup()
    }

    func show() {
        UIView.animate(withDuration: C.animationDuration, animations: {
            self.blur.effect = self.effect
        })
    }

    func hide(completion: @escaping () -> Void) {
        UIView.animate(withDuration: C.animationDuration, animations: {
            self.blur.effect = nil
        }, completion: { _ in
            completion()
        })
    }

    var didTapReset: (() -> Void)? {
        didSet {
            reset.tap = didTapReset
        }
    }

    private let label = UILabel(font: .customBold(size: 20.0), color: .darkText)
    private let label2 = UILabel(font: .customBody(size: 16.0), color: .darkText)
    private let faq: UIButton
    private let blur: UIVisualEffectView
    private let reset = ShadowButton(title: S.UnlockScreen.resetPin, type: .blackTransparent)
    private let effect = UIBlurEffect(style: .light)

    private func setup() {
        addSubviews()
        addConstraints()
        setData()
    }

    private func addSubviews() {
        addSubview(blur)
        addSubview(label)
        addSubview(label2)
        addSubview(faq)
        addSubview(reset)
    }

    private func addConstraints() {
        blur.constrain(toSuperviewEdges: nil)
        label.constrain([
            label.centerYAnchor.constraint(equalTo: blur.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: blur.centerXAnchor) ])
        label2.constrain([
            label2.topAnchor.constraint(equalTo: label.bottomAnchor, constant: C.padding[4]),
            label2.leadingAnchor.constraint(equalTo: blur.leadingAnchor, constant: C.padding[2]),
            label2.trailingAnchor.constraint(equalTo: blur.trailingAnchor, constant: -C.padding[2]),
            label2.centerXAnchor.constraint(equalTo: blur.centerXAnchor) ])
        faq.constrain([
            faq.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            faq.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[2]),
            faq.widthAnchor.constraint(equalToConstant: 44.0),
            faq.heightAnchor.constraint(equalToConstant: 44.0)])
        reset.constrain([
            reset.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            reset.centerYAnchor.constraint(equalTo: faq.centerYAnchor),
            reset.heightAnchor.constraint(equalToConstant: C.Sizes.buttonHeight),
            reset.widthAnchor.constraint(equalToConstant: 200.0) ])
    }

    private func setData() {
        label.textAlignment = .center
        
        label2.textAlignment = .center
        label2.numberOfLines = 4
        label2.text = S.BetSettings.lockWarning
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
