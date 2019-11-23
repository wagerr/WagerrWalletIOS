//
//  WagerrEntities.swift
//  breadwallet
//
//  Created by MIP on 10/11/2019.
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import Foundation

enum MappingNamespaceType : Int32 {
    case SPORT = 0x01
    case ROUNDS = 0x02
    case TEAM_NAME = 0x03
    case TOURNAMENT = 0x04
    case UNKNOWN = -1
}

class BetCore   {
    var blockheight : UInt64;
    var timestamp : TimeInterval;
    var txHash : String;
    var version : UInt32
    
    init(blockheight: UInt64, timestamp: TimeInterval, txHash: String, version: UInt32) {
        self.blockheight = blockheight
        self.timestamp = timestamp
        self.txHash = txHash
        self.version = version
    }
    
    func SaveToDB(_ db : CoreDatabase ) {
        // not implemented in base class
        assert(false)
    }
}

class BetMapping : BetCore   {
    var namespaceID : MappingNamespaceType
    var mappingID : UInt32
    var description : String;

    init(blockheight : UInt64 , timestamp : TimeInterval , txHash : String, version : UInt32, namespaceID : MappingNamespaceType, mappingID : UInt32, description : String )   {
        self.namespaceID = namespaceID
        self.mappingID = mappingID
        self.description = description
        super.init(blockheight: blockheight, timestamp: timestamp, txHash: txHash, version: version)
    }
    
    override func SaveToDB(_ db : CoreDatabase ) {
        db.saveBetMapping( self )
    }
}

enum EventMultipliers  {
    static let ODDS_MULTIPLIER = 10000
    static let SPREAD_MULTIPLIER = 10
    static let TOTAL_MULTIPLIER = 10
    static let RESULT_MULTIPLIER = 10
}

class BetEventDatabaseModel : BetCore {
    var lastUpdated : TimeInterval
    var type : BetTransactionType
    var eventID : UInt64
    var eventTimestamp : TimeInterval

    var sportID : UInt32
    var tournamentID : UInt32
    var roundID : UInt32

    var homeTeamID : UInt32
    var awayTeamID : UInt32

    var homeOdds : UInt32
    var awayOdds : UInt32
    var drawOdds : UInt32

    var entryPrice : UInt32

    var spreadPoints : UInt32
    var spreadHomeOdds : UInt32
    var spreadAwayOdds : UInt32

    var totalPoints : UInt32
    var overOdds : UInt32
    var underOdds : UInt32
    
    init(blockheight: UInt64, timestamp: TimeInterval, lastUpdated: TimeInterval, txHash: String, version: UInt32, type: BetTransactionType, eventID: UInt64, eventTimestamp: TimeInterval, sportID: UInt32, tournamentID: UInt32, roundID: UInt32, homeTeamID: UInt32, awayTeamID: UInt32, homeOdds: UInt32, awayOdds: UInt32, drawOdds: UInt32, entryPrice: UInt32, spreadPoints: UInt32, spreadHomeOdds: UInt32, spreadAwayOdds: UInt32, totalPoints: UInt32, overOdds: UInt32, underOdds: UInt32) {
        self.lastUpdated = lastUpdated
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
        super.init(blockheight: blockheight, timestamp: timestamp, txHash: txHash, version: version)
    }

    override func SaveToDB(_ db : CoreDatabase ) {
        switch self.type {
            case .EVENT_PEERLESS:
                db.saveBetEvent( self )
            
            case .UPDATE_PEERLESS:
                db.updateOdds( self )
            
            case .EVENT_PEERLESS_SPREAD:
                db.updateSpreads( self )
            
            case .EVENT_PEERLESS_TOTAL:
                db.updateTotals( self )
                
            default:    // never happen
                assert(false);
        }
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
    var homeScore : UInt32
    var awayScore : UInt32
    
    init(blockheight: UInt64, timestamp: TimeInterval, lastUpdated: TimeInterval, txHash: String, version: UInt32, type: BetTransactionType, eventID: UInt64, eventTimestamp: TimeInterval, sportID: UInt32, tournamentID: UInt32, roundID: UInt32, homeTeamID: UInt32, awayTeamID: UInt32, homeOdds: UInt32, awayOdds: UInt32, drawOdds: UInt32, entryPrice: UInt32, spreadPoints: UInt32, spreadHomeOdds: UInt32, spreadAwayOdds: UInt32, totalPoints: UInt32, overOdds: UInt32, underOdds: UInt32,
        txSport: String, txTournament: String, txRound: String, txHomeTeam: String, txAwayTeam: String, resultType: BetResultType, homeScore: UInt32, awayScore: UInt32) {
        
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

class BetResult : BetCore {
    
    var type : BetTransactionType
    var eventID : UInt64
    var resultType : BetResultType
    var homeScore : UInt32
    var awayScore : UInt32

    init(blockheight: UInt64, timestamp: TimeInterval, txHash: String, version: UInt32, type: BetTransactionType, eventID: UInt64, resultType: BetResultType, homeScore: UInt32, awayScore: UInt32) {
        self.type = type
        self.eventID = eventID
        self.resultType = resultType
        self.homeScore = homeScore
        self.awayScore = awayScore
        super.init(blockheight: blockheight, timestamp: timestamp, txHash: txHash, version: version)
    }
    
    override func SaveToDB(_ db : CoreDatabase ) {
        db.saveBetResult( self )
    }
}

enum BetType : Int32 {
    case PEERLESS = 0x03
    case CHAINLOTTO = 0x07
    case UNKNOWN = -1
}

enum BetOutcome : Int32 {
     case MONEY_LINE_HOME_WIN = 0x01
     case MONEY_LINE_AWAY_WIN = 0x02
     case MONEY_LINE_DRAW = 0x03
     case SPREADS_HOME = 0x04
     case SPREADS_AWAY = 0x05
     case TOTAL_OVER = 0x06
     case TOTAL_UNDER = 0x07
     case UNKNOWN = -1
}

class BetEntity : BetCore {
    var type : BetType
    var eventID : UInt64
    var outcome : BetOutcome
    var amount : UInt64

    init(blockheight: UInt64, timestamp: TimeInterval, txHash: String, version: UInt32, type: BetType, eventID: UInt64, outcome: BetOutcome, amount: UInt64) {
        self.type = type
        self.eventID = eventID
        self.outcome = outcome
        self.amount = amount
        super.init(blockheight: blockheight, timestamp: timestamp, txHash: txHash, version: version)
    }
}

enum BetTransactionType : Int8 {
    case MAPPING = 0x01
    case EVENT_PEERLESS = 0x02
    case BET_PEERLESS = 0x03
    case RESULT_PEERLESS = 0x04
    case UPDATE_PEERLESS = 0x05
    case EVENT_CHAIN_LOTTO = 0x06
    case BET_CHAIN_LOTTO = 0x07
    case RESULT_CHAIN_LOTTO = 0x08
    case EVENT_PEERLESS_SPREAD = 0x09
    case EVENT_PEERLESS_TOTAL = 0x0a
    case UNKNOWN = -1
}

