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
    var error : String?
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

enum TickersResponse : Codable {
    case string(String)
    case innerItem(TickersResponseObject)

    var objectValue: TickersResponseObject? {
        switch self {
        case .innerItem(let ii):
            return ii
        default:
            return nil
        }
    }

    var stringValue: String? {
        switch self {
        case .string(let s):
            return s
        default:
            return nil
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if let x = try? container.decode(TickersResponseObject.self) {
            self = .innerItem(x)
            return
        }
        throw DecodingError.typeMismatch(TickersResponse.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for TickersResponse"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x):
            try container.encode(x)
        case .innerItem(let x):
            try container.encode(x)
        }
    }
}

struct TickersResponseObject : Codable {
    var min : Double
    var isAllowed : Bool?
    var getAmount : String
    var maxDigitsAfterDecimal : String?
    var TransactionSumFee : String
    
    init(min: Double, isAllowed: Bool? = nil, getAmount: String, maxDigitsAfterDecimal : String? = nil, TransactionSumFee : String) {
        self.min = min
        self.isAllowed = isAllowed
        self.getAmount = getAmount
        self.maxDigitsAfterDecimal = maxDigitsAfterDecimal
        self.TransactionSumFee = TransactionSumFee
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(String.self, forKey: .min) {
            min = Double(value)!
        } else {
            min = try container.decode(Double.self, forKey: .min)
        }
        isAllowed = try? container.decode(Bool.self, forKey: .isAllowed)
        getAmount = try container.decode(String.self, forKey: .getAmount)
        maxDigitsAfterDecimal = try? container.decode(String.self, forKey: .maxDigitsAfterDecimal)
        if let value = try? container.decode(Double.self, forKey: .TransactionSumFee) {
            TransactionSumFee = String(value)
        } else {
            TransactionSumFee = try container.decode(String.self, forKey: .TransactionSumFee)
        }
    }
}

enum AllowedPairsResult {
    case success([String])
    case error(String)
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

struct SwapData : Codable {
    var error : String?
    var apiInfo : String?
    var response : SwapResponse?
}

enum SwapResponse : Codable {
    case string(String)
    case innerItem(SwapResponseObject)

    var objectValue: SwapResponseObject? {
        switch self {
        case .innerItem(let ii):
            return ii
        default:
            return nil
        }
    }

    var stringValue: String? {
        switch self {
        case .string(let s):
            return s
        default:
            return nil
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if let x = try? container.decode(SwapResponseObject.self) {
            self = .innerItem(x)
            return
        }
        throw DecodingError.typeMismatch(SwapResponse.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for SwapResponse"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x):
            try container.encode(x)
        case .innerItem(let x):
            try container.encode(x)
        }
    }
}

struct SwapResponseObject : Codable {
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
        return S.Instaswap.ID + ": " + response.transactionId
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
