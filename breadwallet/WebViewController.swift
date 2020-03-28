//
//  TxDetailViewController.swift
//  breadwallet
//
//  Created by Ehsan Rezaie on 2018-01-18.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import UIKit
import WebKit

private extension C {
    static let statusRowHeight: CGFloat = 48.0
    static let compactContainerHeight: CGFloat = 322.0
    static let expandedContainerHeight: CGFloat = 546.0
    static let detailsButtonHeight: CGFloat = 65.0
}

class WebViewController: UIViewController, WKNavigationDelegate {
    
    // MARK: - Private Vars
    
    private let container = UIView()
    private let tapView = UIView()
    private let header: ModalHeaderView
    private var containerHeightConstraint: NSLayoutConstraint!
    lazy var webView: WKWebView = {
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        //webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    private let theURL : String
    
    private var isExpanded: Bool = false
    
    private var compactContainerHeight: CGFloat {
        let windowRect = self.view.frame
        //CGFloat windowWidth = windowRect.size.width;
        return (windowRect.size.height) * 0.85
    }
    
    private var expandedContainerHeight: CGFloat {
        return C.compactContainerHeight
    }
    
    // MARK: - Init
    
    init(theURL: String) {
        self.theURL = theURL
        self.header = ModalHeaderView(title: "", style: .transaction, faqInfo: ArticleIds.transactionDetails)
        
        super.init(nibName: nil, bundle: nil)
        
        header.closeCallback = { [weak self] in
            self?.close()
        }
        
        setup()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated  {
            if let url = navigationAction.request.url,
                let host = url.host, !host.hasPrefix("www.betsmart.app"),
                UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url)
                } else {
                    // Fallback on earlier versions
                }
                print(url)
                print("Redirected to browser. No need to open it locally")
                decisionHandler(.cancel)
            } else {
                print("Open it locally")
                decisionHandler(.allow)
            }
        } else {
            print("not a user click")
            decisionHandler(.allow)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        view.addSubview(tapView)
        view.addSubview(container)
        container.addSubview(header)
        container.addSubview(webView)
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
        
        webView.constrain([
            webView.topAnchor.constraint(equalTo: header.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        header.constrainTopCorners(height: C.Sizes.headerHeight)
    }
    
    private func setupActions() {
        let gr = UITapGestureRecognizer(target: self, action: #selector(close))
        tapView.addGestureRecognizer(gr)
        tapView.isUserInteractionEnabled = true
    }
    
    private func setInitialData() {
        container.layer.cornerRadius = C.Sizes.roundedCornerRadius
        container.layer.masksToBounds = true
        
        header.setTitle( "" )
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
