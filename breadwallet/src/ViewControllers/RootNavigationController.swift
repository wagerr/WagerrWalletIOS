//
//  RootNavigationController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-12-05.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit

class RootNavigationController : UINavigationController {

    var walletManager: BTCWalletManager? {
        didSet {
            guard let walletManager = walletManager else { return }
            if !walletManager.noWallet && Store.state.isLoginRequired {
                let loginView = LoginViewController(isPresentedForLock: false, walletManager: walletManager)
                loginView.transitioningDelegate = loginTransitionDelegate
                loginView.modalPresentationStyle = .overFullScreen
                loginView.modalPresentationCapturesStatusBarAppearance = true
                loginView.shouldSelfDismiss = true
                present(loginView, animated: false, completion: {
                    self.tempLoginView.remove()
                })
            }
        }
    }

    private var tempLoginView = LoginViewController(isPresentedForLock: false)
    private let welcomeTransitingDelegate = PinTransitioningDelegate()
    private let loginTransitionDelegate = LoginTransitionDelegate()

    override func viewDidLoad() {
        setLightStyle()
        navigationBar.isTranslucent = false
        self.addChildViewController(tempLoginView, layout: {
            tempLoginView.view.constrain(toSuperviewEdges: nil)
        })
        guardProtected(queue: DispatchQueue.main) {
            if BTCWalletManager.staticNoWallet {
                self.tempLoginView.remove()
                let tempStartView = StartViewController(didTapCreate: {}, didTapRecover: {})
                self.addChildViewController(tempStartView, layout: {
                    tempStartView.view.constrain(toSuperviewEdges: nil)
                    tempStartView.view.isUserInteractionEnabled = false
                })
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    tempStartView.remove()
                })
            }
        }
        self.delegate = self
    }

    func checkGitHubVersion(controller: UIViewController,completion: @escaping (Bool)->Void) {
        self.fetchGitHubVersion( completion: { data in
            guard let data = data else { return }
            let appVersion  = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            let appBuild  = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
            let nBuild = Int(appBuild) ?? 0
            let nGithub = Int(data) ?? 0
            if ( nBuild < nGithub )   {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: S.BetSettings.newVersionTitle, message: S.BetSettings.newVersion, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: S.BetSettings.goTo, style: .default, handler: { _ in
                        let url = URL(string:"https://iosapp.wagerr.com/")!
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    }))
                    controller.present(alert, animated: true, completion: { () -> Void in
                        return
                    })
                }
                DispatchQueue.main.async    {   // completion affects UI
                    completion(false)
                }
            }
            else    {
                DispatchQueue.main.async    {
                    completion(true)
                }
            }
        })
    }
    
    func fetchGitHubVersion(completion: @escaping (String?)->Void) {
        let path = "https://api.github.com/repos/wagerr/WagerrWalletiOS/releases/latest";
        let url = URL(string: path)!
        var req = URLRequest(url: URL(string: path)!)
        req.httpMethod = "GET"
        //req.httpBody = "addrs=\(address)".data(using: .utf8)
        let task = URLSession.shared.dataTask(with: url) {(data, resp, error) in
            guard error == nil else { completion(""); return }
            if  let data = data,
                let jsonData = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] {
                if let version = jsonData["tag_name"] as? String {
                    completion(version)
                }
            }
            else { completion(""); return }
        }
        task.resume()
    }

    func attemptShowWelcomeView() {
        //if !UserDefaults.hasShownWelcome {
        if (false)  {   // disable
            let welcome = WelcomeViewController()
            welcome.transitioningDelegate = welcomeTransitingDelegate
            welcome.modalPresentationStyle = .overFullScreen
            welcome.modalPresentationCapturesStatusBarAppearance = true
            welcomeTransitingDelegate.shouldShowMaskView = false
            topViewController?.present(welcome, animated: true, completion: nil)
            UserDefaults.hasShownWelcome = true
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if topViewController is HomeScreenViewController || topViewController is EditWalletsViewController {
            return .default
        } else {
            return .lightContent
        }
    }

    func setLightStyle() {
        navigationBar.tintColor = .whiteBackground
    }

    func setDarkStyle() {
        navigationBar.tintColor = .black
    }
}

extension RootNavigationController : UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController is HomeScreenViewController {
            UserDefaults.selectedCurrencyCode = nil
        } else if let accountView = viewController as? AccountViewController {
            UserDefaults.selectedCurrencyCode = accountView.currency.code
            UserDefaults.mostRecentSelectedCurrencyCode = accountView.currency.code
        }
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is EditWalletsViewController {
            setDarkStyle()
        } else {
            setLightStyle()
        }
    }
}
