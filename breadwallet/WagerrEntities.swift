//
//  WagerrEntities.swift
//  breadwallet
//
//  Created by F.J. Ortiz on 10/11/2019.
//  Copyright © 2019 breadwallet LLC. All rights reserved.
//

import Foundation

enum MappingNamespaceType : Int32 {
    case SPORT = 0x01
    case ROUNDS = 0x02
    case TEAM_NAME = 0x03
    case TOURNAMENT = 0x04
    case UNKNOWN = -1
}

class BetMapping    {
    var blockheight : UInt64;
    var timestamp : TimeInterval;
    var txHash : String;
    var version : Int32
    var namespaceID : MappingNamespaceType
    var mappingID : UInt32
    var description : String;

    init(blockheight : UInt64 , timestamp : TimeInterval , txHash : String, version : Int32, namespaceID : MappingNamespaceType, mappingID : UInt32, description : String )   {
        self.blockheight = blockheight
        self.timestamp = timestamp
        self.txHash = txHash
        self.version = version
        self.namespaceID = namespaceID
        self.mappingID = mappingID
        self.description = description
    }
}

enum EventMultipliers  {
    static let ODDS_MULTIPLIER = 10000
    static let SPREAD_MULTIPLIER = 10
    static let TOTAL_MULTIPLIER = 10
    static let RESULT_MULTIPLIER = 10
}

class BetEventDatabaseModel  {
    var blockheight : UInt64
    var timestamp : Int32
    var lastUpdated : Int32
    var txHash : String
    var version : Int32
    var type : BetTransactionType
    var eventID : UInt64
    var eventTimestamp : Int32

    var sportID : Int32
    var tournamentID : Int32
    var roundID : Int32

    var homeTeamID : Int32
    var awayTeamID : Int32

    var homeOdds : Int32
    var awayOdds : Int32
    var drawOdds : Int32

    var entryPrice : Int32

    var spreadPoints : Int32
    var spreadHomeOdds : Int32
    var spreadAwayOdds : Int32

    var totalPoints : Int32
    var overOdds : Int32
    var underOdds : Int32
    
    init(blockheight: UInt64, timestamp: Int32, lastUpdated: Int32, txHash: String, version: Int32, type: BetTransactionType, eventID: UInt64, eventTimestamp: Int32, sportID: Int32, tournamentID: Int32, roundID: Int32, homeTeamID: Int32, awayTeamID: Int32, homeOdds: Int32, awayOdds: Int32, drawOdds: Int32, entryPrice: Int32, spreadPoints: Int32, spreadHomeOdds: Int32, spreadAwayOdds: Int32, totalPoints: Int32, overOdds: Int32, underOdds: Int32) {
        self.blockheight = blockheight
        self.timestamp = timestamp
        self.lastUpdated = lastUpdated
        self.txHash = txHash
        self.version = version
        self.type = type
        self.eventID = eventID
        self.eventTimestamp = eventTimestamp
        self.sportID = sportID
        self.tournamentID = tournamentID
        self.roundID = roundID
        self.homeTeamID = homeTeamID
        self.awayTeamID = awayTeamID
        self.homeOdds = homeOdds
        self.awayOdds = awayOdds
        self.drawOdds = drawOdds
        self.entryPrice = entryPrice
        self.spreadPoints = spreadPoints
        self.spreadHomeOdds = spreadHomeOdds
        self.spreadAwayOdds = spreadAwayOdds
        self.totalPoints = totalPoints
        self.overOdds = overOdds
        self.underOdds = underOdds
    }

}

class BetEventViewModel : BetEventDatabaseModel {
    // mappings
    var txSport : String
    var txTournament : String
    var txRound : String
    var txHomeTeam : String
    var txAwayTeam : String

    // results
    var resultType : BetResultType
    var homeScore : Int32
    var awayScore : Int32
    
    init(blockheight: UInt64, timestamp: Int32, lastUpdated: Int32, txHash: String, version: Int32, type: BetTransactionType, eventID: UInt64, eventTimestamp: Int32, sportID: Int32, tournamentID: Int32, roundID: Int32, homeTeamID: Int32, awayTeamID: Int32, homeOdds: Int32, awayOdds: Int32, drawOdds: Int32, entryPrice: Int32, spreadPoints: Int32, spreadHomeOdds: Int32, spreadAwayOdds: Int32, totalPoints: Int32, overOdds: Int32, underOdds: Int32,
        txSport: String, txTournament: String, txRound: String, txHomeTeam: String, txAwayTeam: String, resultType: BetResultType, homeScore: Int32, awayScore: Int32) {
        
        self.txSport = txSport
        self.txTournament = txTournament
        self.txRound = txRound
        self.txHomeTeam = txHomeTeam
        self.txAwayTeam = txAwayTeam
        self.resultType = resultType
        self.homeScore = homeScore
        self.awayScore = awayScore
        super.init(blockheight: blockheight, timestamp: timestamp, lastUpdated: lastUpdated, txHash: txHash, version: version, type: type, eventID: eventID, eventTimestamp: eventTimestamp, sportID: sportID, tournamentID: tournamentID, roundID: roundID, homeTeamID: homeTeamID, awayTeamID: awayTeamID, homeOdds: homeOdds, awayOdds: awayOdds, drawOdds: drawOdds, entryPrice: entryPrice, spreadPoints: spreadPoints, spreadHomeOdds: spreadHomeOdds, spreadAwayOdds: spreadAwayOdds, totalPoints: totalPoints, overOdds: overOdds, underOdds: underOdds)
    }
}

enum BetResultType : Int32 {
    case STANDARD_PAYOUT = 0x01
    case EVENT_REFUND = 0x02
    case MONEYLINE_REFUND = 0x03
    case UNKNOWN = -1
}

class BetResult {
    
    var blockheight : UInt64;
    var timestamp : Int32;
    var txHash : String;
    var version : Int32
    var type : BetTransactionType
    var eventID : UInt64
    var resultType : BetResultType
    var homeScore : Int32
    var awayScore : Int32

    init(blockheight: UInt64, timestamp: Int32, txHash: String, version: Int32, type: BetTransactionType, eventID: UInt64, resultType: BetResultType, homeScore: Int32, awayScore: Int32) {
        self.blockheight = blockheight
        self.timestamp = timestamp
        self.txHash = txHash
        self.version = version
        self.type = type
        self.eventID = eventID
        self.resultType = resultType
        self.homeScore = homeScore
        self.awayScore = awayScore
    }
    
}
