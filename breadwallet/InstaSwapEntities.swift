//
//  InstaSwapEntities.swift
//  Wagerr Pro
//
//  Created by MIP on 5/2/2020.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import Foundation
import UIKit

struct ReportAllowedPairsData : Codable {
    var apiInfo : String
    var response : [ReportAllowedPairsResponse]
}

struct ReportAllowedPairsResponse : Codable {
    var depositCoin : String
    var receiveCoin : String
    var depositCoinFullName : String
    var receiveCoinFullName : String
}

struct TickersData : Codable {
    var error : String?
    var apiInfo : String?
    var response : TickersResponse?
}

enum TickersResult {
    case success(TickersData)
    case error(String)
}

enum SwapResult {
    case success(SwapData)
    case error(String)
}

enum SwapHistoryResult {
    case success(ReportSwapHistoryData)
    case error(String)
}

struct TickersResponse : Codable {
    var min : Double
    var getAmount : String
    var maxDigitsAfterDecimal : String
    var TransactionSumFee : String
}

struct SwapData : Codable {
    var error : String?
    var apiInfo : String?
    var response : SwapResponse?
}

struct SwapResponse : Codable {
    var TransactionId : String
    var depositWallet : String
    var receivingAmount : String
}

struct SwapStateData : Codable {
    var apiInfo : String
    var response : SwapStateResponse
}

enum SwapTransactionState : String, Codable{
    case awaiting = "Awaiting Deposit"
    case swaping = "Swaping"
    case withdraw = "Withdraw"
    case completed = "Completed"
    case notcompleted = "Deposit Not Completed"
}

struct SwapStateResponse : Codable {
    var moonpayProfit : String?
    var ourTransactionKeyId : String
    var externalTransactionId : String?
    var btcGetVal : String?
    var isFiatTransaction : String?
    var fiatResponse : String?
    var transactionId : String
    var depositCoin : String
    var receiveCoin : String
    var depositAmount : String
    var receivingAmount : String
    var refundWallet : String
    var receiveWallet : String
    var depositWallet : String
    var memo_tag : String
    var transactionState : SwapTransactionState
    var timestamp : String
    
    func getAttrTimestamp() -> NSAttributedString  {
        let tsAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.colorDraw]
        let ret = NSMutableAttributedString(string: timestamp, attributes: tsAttrs)
        return ret
    }
    
    func getAttrAmount() -> NSAttributedString  {
        let tsAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.receivedGreen]
        let ret = NSMutableAttributedString(string: receivingAmount + " " + receiveCoin, attributes: tsAttrs)
        return ret
    }
}

class SwapViewModel : Equatable {
    let response : SwapStateResponse
    
    init(response: SwapStateResponse) {
        self.response = response
    }
    
    var currency : CurrencyDef  {
        return Currencies.btc
    }
    
    var title : String {
        return response.transactionId
    }
    
    static func ==(lhs: SwapViewModel, rhs: SwapViewModel) -> Bool {
        return  lhs.response.transactionId == rhs.response.transactionId &&
            lhs.response.transactionState == rhs.response.transactionState
    }

    static func !=(lhs: SwapViewModel, rhs: SwapViewModel) -> Bool {
        return !(lhs == rhs)
    }
}

struct ReportSwapHistoryData : Codable  {
    var error : String?
    var apiInfo : String?
    var response : [SwapStateResponse]
}

struct InstaswapRequest {
    var command : String
    var parameters : [ String: String ]
}
