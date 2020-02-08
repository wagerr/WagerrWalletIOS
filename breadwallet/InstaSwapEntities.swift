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
    var apiInfo : String
    var response : TickersResponse
}

struct TickersResponse : Codable {
    var min : Double
    var getAmount : Double
    var minDigitsAfterDecimal : Int
}

struct SwapData : Codable {
    var apiInfo : String
    var response : SwapStateResponse
}

struct SwapResponse : Codable {
    var TransactionId : String
    var depositWallet : String
    var receivingAmount : Double
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
    var transactionId : String
    var depositCoin : String
    var receiveCoin : String
    var depositAmount : Double
    var refundWallet : String
    var receiveWallet : String
    var depositWallet : String
    var memo_tag : String
    var transactionState : SwapTransactionState
    var timestamp : String
}

struct ReportSwapHistoryData : Codable  {
    var apiInfo : String
    var response : [SwapStateResponse]
}

struct InstaswapRequest {
    var command : String
    var parameters : [ String: String ]
}
