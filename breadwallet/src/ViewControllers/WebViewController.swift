//
//  WebViewController.swift
//  breadwallet
//
//  Created by MIP on 2020-03-26.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
    
    // MARK: - Private Vars
    private let container = UIView()
    lazy var webView: WKWebView = {
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        //webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    private let close = UIButton(type: .system)
    
    private var containerHeightConstraint: NSLayoutConstraint!
    
    public override var preferredContentSize: CGSize {
        get {
            return CGSize(width: 300.0,
                          height: 500.0)
        }

        set { super.preferredContentSize = newValue }
    }
    private let theURL : String
    // MARK: - Init

    init(theURL: String) {
        self.theURL = theURL
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        let url = URL(string: theURL)!
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = false
    }
    
    private func setup() {
        addSubViews()
        addConstraints()
        setupActions()
        setInitialData()
    }
    
    private func addSubViews() {
        view.addSubview(container)
        container.addSubview(close)
        container.addSubview(webView)
    }
    
    private func addConstraints() {
        container.constrain([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        
        containerHeightConstraint = container.heightAnchor.constraint(equalToConstant: CGFloat(400.0))
        containerHeightConstraint.isActive = true
        
        close.constrain([
            close.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -C.padding[2]),
            close.topAnchor.constraint(equalTo: container.topAnchor, constant: C.padding[2])
            ])
        
        webView.constrain([
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.topAnchor.constraint(equalTo: close.bottomAnchor, constant: 1.0),
            webView.heightAnchor.constraint(equalToConstant: CGFloat(400.0))
        ])
    }
    
    private func setupActions() {
        close.tap = { [weak self] in
            self?.dismiss(animated: true, completion: {
            })
        }
    }
    
    private func setInitialData() {
        close.setBackgroundImage(#imageLiteral(resourceName: "Close"), for: .normal)
        close.frame = CGRect(x: 6.0, y: 6.0, width: 32.0, height: 32.0) // for iOS 10
        close.widthAnchor.constraint(equalToConstant: 32.0).isActive = true
        close.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
        close.tintColor = .white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
