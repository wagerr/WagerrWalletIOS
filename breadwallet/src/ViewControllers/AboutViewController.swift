//
//  AboutViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-04-05.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit
import SafariServices

class AboutViewController : UIViewController {

    private let titleLabel = UILabel(font: .customBold(size: 26.0), color: .darkText)
    private let logo = UIImageView(image: #imageLiteral(resourceName: "LogoGradient"))
    private let logoBackground = GradientView()
    private let walletID = WalletIDCell()
    private let blog = AboutCell(text: S.About.blog)
    private let twitter = AboutCell(text: S.About.twitter)
    private let reddit = AboutCell(text: S.About.reddit)
    private let telegram = AboutCell(text: S.About.telegram)
    private let privacy = UIButton(type: .system)
    private let footer = UILabel(font: .customBody(size: 13.0), color: .darkText)
    private let footer2 = UILabel(font: .customBody(size: 13.0), color: .darkText)
    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        setData()
        setActions()
    }

    private func addSubviews() {
        view.addSubview(titleLabel)
        view.addSubview(logo)
        //logoBackground.addSubview(logo)
        //view.addSubview(walletID)
        view.addSubview(blog)
        view.addSubview(twitter)
        view.addSubview(reddit)
        view.addSubview(telegram)
        view.addSubview(privacy)
        view.addSubview(footer)
        view.addSubview(footer2)
    }

    private func addConstraints() {
        titleLabel.constrain([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            titleLabel.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: C.padding[2]) ])
        logo.constrain([
            logo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logo.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: C.padding[3]),
            logo.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            logo.heightAnchor.constraint(equalTo: logo.widthAnchor, multiplier: 162.0/553.0) ])
        //logo.constrain(toSuperviewEdges: nil)
        /*
        walletID.constrain([
            walletID.topAnchor.constraint(equalTo: logoBackground.bottomAnchor, constant: C.padding[2]),
            walletID.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            walletID.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
 */
        blog.constrain([
            blog.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: C.padding[2]),
            blog.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blog.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
        twitter.constrain([
            twitter.topAnchor.constraint(equalTo: blog.bottomAnchor, constant: C.padding[2]),
            twitter.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            twitter.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
        reddit.constrain([
            reddit.topAnchor.constraint(equalTo: twitter.bottomAnchor, constant: C.padding[2]),
            reddit.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            reddit.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
        telegram.constrain([
            telegram.topAnchor.constraint(equalTo: reddit.bottomAnchor, constant: C.padding[2]),
            telegram.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            telegram.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
        privacy.constrain([
            privacy.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            privacy.topAnchor.constraint(equalTo: telegram.bottomAnchor, constant: C.padding[2])])
        footer.constrain([
            footer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            footer.topAnchor.constraint(equalTo: privacy.bottomAnchor) ])
        footer2.constrain([
            footer2.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            footer2.topAnchor.constraint(equalTo: footer.bottomAnchor) ])
    }

    private func setData() {
        view.backgroundColor = .whiteBackground
        titleLabel.text = S.About.title
        privacy.setTitle(S.About.privacy, for: .normal)
        privacy.titleLabel?.font = UIFont.customBody(size: 13.0)
        footer.textAlignment = .center
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            footer.text = String(format: S.About.footer, "\(version) (\(build))")
            footer2.text = S.About.footer2
        }
    }

    private func setActions() {
        blog.button.tap = strongify(self) { myself in
            myself.presentURL(string: "https://www.wagerr.com/")
        }
        twitter.button.tap = strongify(self) { myself in
            myself.presentURL(string: "https://twitter.com/wagerrx")
        }
        reddit.button.tap = strongify(self) { myself in
            myself.presentURL(string: "https://www.reddit.com/r/Wagerr/")
        }
        telegram.button.tap = strongify(self) { myself in
            myself.presentURL(string: "https://t.me/wagerrcoin")
        }
        privacy.tap = strongify(self) { myself in
            myself.presentURL(string: "https://github.com/wagerr/WagerrWalletAndroid/blob/master/PrivacyPolicy.md")
        }
    }

    private func presentURL(string: String) {
        let vc = SFSafariViewController(url: URL(string: string)!)
        self.present(vc, animated: true, completion: nil)
    }
}
