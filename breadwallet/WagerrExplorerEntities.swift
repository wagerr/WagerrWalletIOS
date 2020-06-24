//
//  InstaSwapEntities.swift
//  Wagerr Pro
//
//  Created by MIP on 12/6/2020.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import Foundation
import UIKit

enum ExplorerTxResult {
    case success(ExplorerTxData)
    case error(String)
}

struct ExplorerTxData : Codable {
    let blockHash : String?
    let blockHeight : Int?
    let createdAt : String?
    let txId : String?
    let version : Int?
    let vin : [ExplorerTxVin]?
    let vout : [ExplorerTxVout]?

    enum CodingKeys: String, CodingKey {
        case blockHash = "blockHash"
        case blockHeight = "blockHeight"
        case createdAt = "createdAt"
        case txId = "txId"
        case version = "version"
        case vin = "vin"
        case vout = "vout"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        blockHash = try values.decodeIfPresent(String.self, forKey: .blockHash)
        blockHeight = try values.decodeIfPresent(Int.self, forKey: .blockHeight)
        createdAt = try values.decodeIfPresent(String.self, forKey: .createdAt)
        txId = try values.decodeIfPresent(String.self, forKey: .txId)
        version = try values.decodeIfPresent(Int.self, forKey: .version)
        vin = try values.decodeIfPresent([ExplorerTxVin].self, forKey: .vin)
        vout = try values.decodeIfPresent([ExplorerTxVout].self, forKey: .vout)
    }
}

struct ExplorerTxVin : Codable {
    let address : String?
    let value : Double?

    enum CodingKeys: String, CodingKey {

        case address = "address"
        case value = "value"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        address = try values.decodeIfPresent(String.self, forKey: .address)
        value = try values.decodeIfPresent(Double.self, forKey: .value)
    }
}

struct ExplorerTxVout : Codable {
    let _id : String?
    let address : String?
    let n : Int?
    let value : Double?
    let price : Double?
    let spread : String?
    let total : String?
    let market : String?
    let eventId : String?
    let betValue : Double?
    let betValueUSD : Double?
    let homeTeam : String?
    let awayTeam : String?
    let league : String?
    let isParlay : Int?
    let legs : [ExplorerTxLegs]?

    enum CodingKeys: String, CodingKey {

        case _id = "_id"
        case address = "address"
        case n = "n"
        case value = "value"
        case price = "price"
        case total = "Total"
        case spread = "Spread"
        case market = "market"
        case eventId = "eventId"
        case betValue = "betValue"
        case betValueUSD = "betValueUSD"
        case homeTeam = "homeTeam"
        case awayTeam = "awayTeam"
        case league = "league"
        case isParlay = "isParlay"
        case legs = "legs"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        _id = try values.decodeIfPresent(String.self, forKey: ._id)
        address = try values.decodeIfPresent(String.self, forKey: .address)
        n = try values.decodeIfPresent(Int.self, forKey: .n)
        value = try values.decodeIfPresent(Double.self, forKey: .value)
        price = try values.decodeIfPresent(Double.self, forKey: .price)
        total = try values.decodeIfPresent(String.self, forKey: .total)
        spread = try values.decodeIfPresent(String.self, forKey: .spread)
        market = try values.decodeIfPresent(String.self, forKey: .market)
        eventId = try values.decodeIfPresent(String.self, forKey: .eventId)
        betValue = try values.decodeIfPresent(Double.self, forKey: .betValue)
        betValueUSD = try values.decodeIfPresent(Double.self, forKey: .betValueUSD)
        homeTeam = try values.decodeIfPresent(String.self, forKey: .homeTeam)
        awayTeam = try values.decodeIfPresent(String.self, forKey: .awayTeam)
        league = try values.decodeIfPresent(String.self, forKey: .league)
        isParlay = try values.decodeIfPresent(Int.self, forKey: .isParlay)
        legs = try values.decodeIfPresent([ExplorerTxLegs].self, forKey: .legs)
    }

}

struct ExplorerTxLegs : Codable {
    let price : Double?
    let eventId : String?
    let homeTeam : String?
    let awayTeam : String?
    let league : String?
    let market : String?
    let outcome : Int?
    let betResult : String?
    let eventResult : String?
    let spread : String?
    let total : String?

    enum CodingKeys: String, CodingKey {

        case price = "price"
        case eventId = "eventId"
        case homeTeam = "homeTeam"
        case awayTeam = "awayTeam"
        case league = "league"
        case market = "market"
        case outcome = "outcome"
        case betResult = "betResult"
        case eventResult = "eventResult"
        case spread = "Spread"
        case total = "Total"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        price = try values.decodeIfPresent(Double.self, forKey: .price)
        eventId = try values.decodeIfPresent(String.self, forKey: .eventId)
        homeTeam = try values.decodeIfPresent(String.self, forKey: .homeTeam)
        awayTeam = try values.decodeIfPresent(String.self, forKey: .awayTeam)
        league = try values.decodeIfPresent(String.self, forKey: .league)
        market = try values.decodeIfPresent(String.self, forKey: .market)
        outcome = try values.decodeIfPresent(Int.self, forKey: .outcome)
        betResult = try values.decodeIfPresent(String.self, forKey: .betResult)
        eventResult = try values.decodeIfPresent(String.self, forKey: .eventResult)
        total = try values.decodeIfPresent(String.self, forKey: .total)
        spread = try values.decodeIfPresent(String.self, forKey: .spread)
    }

}
