//
//  Constants.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-10-24.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit

let π: CGFloat = .pi

struct Padding {
    subscript(multiplier: CGFloat) -> CGFloat {
        get {
            return CGFloat(multiplier) * 8.0
        }
    }
}

struct C {
    static let padding = Padding()
    struct Sizes {
        static let buttonHeight: CGFloat = 48.0
        static let headerHeight: CGFloat = 48.0
        static let largeHeaderHeight: CGFloat = 220.0
        static let logoAspectRatio: CGFloat = 125.0/417.0
        static let roundedCornerRadius: CGFloat = 6.0
    }
    static var defaultTintColor: UIColor = {
        return UIView().tintColor
    }()
    static let animationDuration: TimeInterval = 0.3
    static let secondsInDay: TimeInterval = 86400
    static let maxMoney: UInt64 = 5100000000*100000000
    static let satoshis: UInt64 = 100000000
    static let walletQueue = "com.wagerrwallet.walletqueue"
    static let null = "(null)"
    static let maxMemoLength = 250
    static let feedbackEmail = "support@wagerr.com"
    static let iosEmail = "support@wagerr.com"
    static let reviewLink = "itms-apps://itunes.apple.com/app/id1393817110?action=write-review"
    static var standardPort: Int {
        return E.isTestnet ? 19229 : 9229
    }
    static let feeCacheTimeout: TimeInterval = C.secondsInDay*3
    static let bCashForkBlockHeight: UInt32 = E.isTestnet ? 1155876 : 478559
    static let bCashForkTimeStamp: TimeInterval = E.isTestnet ? (1501597117 - NSTimeIntervalSince1970) : (1501568580 - NSTimeIntervalSince1970)
    static let txUnconfirmedHeight = Int32.max
    
    static let consoleLogFileName = "log.txt"
    static let previousConsoleLogFileName = "previouslog.txt"
       
    static var logFilePath: URL {
        let cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        return URL(fileURLWithPath: cachesDirectory).appendingPathComponent("log.txt")
    }
    // Returns the console log file path for the previous instantiation of the app.
    static var previousLogFilePath: URL {
        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesURL.appendingPathComponent(previousConsoleLogFileName)
    }
    static let usdCurrencyCode = "USD"
    static let erc20Prefix = "erc20:"
}

enum Words {
    static var wordList: [NSString]? {
        guard let path = Bundle.main.path(forResource: "BIP39Words", ofType: "plist") else { return nil }
        return NSArray(contentsOfFile: path) as? [NSString]
    }

    static var rawWordList: [UnsafePointer<CChar>?]? {
        guard let wordList = Words.wordList, wordList.count == 2048 else { return nil }
        return wordList.map({ $0.utf8String })
    }
}

// Wagerr constants
struct W    {
    struct BetAmount    {
        static let min: Float = 25.0
        static let max: Float = 10000.0
    }
    struct FontSize {
        static let normalSize = CGFloat(24.0)
        static let selectSize = CGFloat(30.0)
    }
}
