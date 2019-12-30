//
//  WagerrEntities.swift
//  breadwallet
//
//  Created by MIP on 10/11/2019.
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import Foundation
import UIKit

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

class BetSport : BetMapping {
    var id : UInt32 {
        return mappingID
    }
}

class BetTournament : BetMapping {
    var id : UInt32 {
        return mappingID
    }
}

enum EventMultipliers  {
    static var ODDS_MULTIPLIER : UInt32 = 10000
    static var SPREAD_MULTIPLIER : UInt32 = 10
    static var TOTAL_MULTIPLIER : UInt32 = 10
    static var RESULT_MULTIPLIER : UInt32 = 10
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
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSSS"
        switch self.type {
            case .EVENT_PEERLESS:
                db.saveBetEvent( self )
            
            case .UPDATE_PEERLESS:
                print(String.init(format: "%@: updateOdds %d: %@/%@/%@", formatter.string(from: date), self.eventID, self.txHomeOdds, self.txDrawOdds, self.txAwayOdds))
                db.updateOdds( self )
            
            case .EVENT_PEERLESS_SPREAD:
                print(String.init(format: "%@: updateSpread %d: %@/%@", formatter.string(from: date), self.eventID, self.txHomeSpread, self.txAwaySpread))
                db.updateSpreads( self )
            
            case .EVENT_PEERLESS_TOTAL:
                print(String.init(format: "%@: updateTotals %d: %@/%@", formatter.string(from: date), self.eventID, self.txOverOdds, self.txUnderOdds))
                db.updateTotals( self )
                
            default:    // never happen
                assert(false);
        }
    }
    
    var txHomeOdds : String {
        return (homeOdds==0) ? "N/A" : String(format: "%.2f", getOdd(odd: Float(homeOdds) / Float(EventMultipliers.ODDS_MULTIPLIER) ) )
    }
    var txAwayOdds : String {
        return (awayOdds==0) ? "N/A" : String(format: "%.2f", getOdd(odd:Float(awayOdds) / Float(EventMultipliers.ODDS_MULTIPLIER) ) )
    }
    var txDrawOdds : String {
        return (drawOdds==0) ? "N/A" : String(format: "%.2f", getOdd(odd:Float(drawOdds) / Float(EventMultipliers.ODDS_MULTIPLIER) ) )
    }
    var txSpreadPoints : String {
        return (spreadPoints==0) ? "N/A" : String(format: "%.1f", Float(spreadPoints) / Float(EventMultipliers.SPREAD_MULTIPLIER) )
    }
    
    func getOdd( odd : Float ) -> Float   {
        return (UserDefaults.showNetworkFeesInOdds) ? odd : ((odd-1)*0.94)+1
    }
    
    var txSpreadPointsFormatted : String    {
        let fmt = (homeOdds>awayOdds) ? "+%@/-%@" : "-%@/+%@"
        return String.init(format: fmt, txSpreadPoints, txSpreadPoints)
    }
    
    var txHomeSpread : String {
        return (spreadHomeOdds==0) ? "N/A" : String(format: "%.2f", getOdd(odd: Float(spreadHomeOdds) / Float(EventMultipliers.ODDS_MULTIPLIER) ) )
    }
    var txAwaySpread : String {
        return (spreadAwayOdds==0) ? "N/A" : String(format: "%.2f", getOdd(odd: Float(spreadAwayOdds) / Float(EventMultipliers.ODDS_MULTIPLIER) ))
    }
    var txTotalPoints : String {
        return (totalPoints==0) ? "N/A" : String(format: "%.1f", Float(totalPoints) / Float(EventMultipliers.TOTAL_MULTIPLIER) )
    }
    var txOverOdds : String {
        return (overOdds==0) ? "N/A" : String(format: "%.2f", getOdd(odd: Float(overOdds) / Float(EventMultipliers.ODDS_MULTIPLIER) ))
    }
    var txUnderOdds : String {
        return (underOdds==0) ? "N/A" : String(format: "%.2f", getOdd(odd: Float(underOdds) / Float(EventMultipliers.ODDS_MULTIPLIER) ))
    }
    
    var hasSpreads : Bool   {
        return (spreadPoints>0)
    }
    var hasTotals : Bool   {
        return (totalPoints>0)
    }
}

class BetEventViewModel : BetEventDatabaseModel, Equatable {
    
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
    
    static func ==(lhs: BetEventViewModel, rhs: BetEventViewModel) -> Bool {
        return  lhs.eventID == rhs.eventID &&
            lhs.homeOdds == rhs.homeOdds &&
            lhs.drawOdds == rhs.drawOdds &&
            lhs.awayOdds == rhs.awayOdds &&
            lhs.spreadHomeOdds == rhs.spreadHomeOdds &&
            lhs.spreadAwayOdds == rhs.spreadAwayOdds &&
            lhs.overOdds == rhs.overOdds &&
            lhs.underOdds == rhs.underOdds &&
            lhs.spreadPoints == rhs.spreadPoints &&
            lhs.totalPoints == rhs.totalPoints &&
            lhs.eventTimestamp == rhs.eventTimestamp
    }

    static func !=(lhs: BetEventViewModel, rhs: BetEventViewModel) -> Bool {
        return !(lhs == rhs)
    }
    
    var currency: CurrencyDef { return Currencies.btc }     // always WGR
    
    var shortTimestamp: String {
        let date = Date(timeIntervalSinceReferenceDate: eventTimestamp)
        return DateFormatter.eventDateFormatter.string(from: date)
    }
    var eventDescription: String {
        var ret = ""
        if (!txSport.isEmpty)   { ret.append(txSport) }
        if (!txTournament.isEmpty)   {
            if (!ret.isEmpty)   { ret.append(" - ") }
            ret.append(txTournament)
        }
        if (!txRound.isEmpty)   {
            if (!ret.isEmpty)   { ret.append(" - ") }
            ret.append(txRound)
        }
        //return String(format: "%@ - %@ - %@", txSport, txTournament, txRound)
        return ret
    }
    var title : String {
        return self.eventDescription
    }
    
    var oddsDescription: NSAttributedString {
        let homeAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.colorHome]
        let drawAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.colorDraw]
        let awayAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.colorAway]
        
        let ret = NSMutableAttributedString(string: txHomeOdds, attributes: homeAttrs)
        let separator = NSAttributedString(string: " / ")
        let draw = NSAttributedString(string: txDrawOdds, attributes: drawAttrs)
        let away = NSAttributedString(string: txAwayOdds, attributes: awayAttrs)
        ret.append(separator)
        ret.append(draw)
        ret.append(separator)
        ret.append(away)
        
        return ret
    }
    var txHomeScore : String {
        return String(format: "%d", homeScore / EventMultipliers.RESULT_MULTIPLIER )
    }
    var txAwayScore : String {
        return String(format: "%d", awayScore / EventMultipliers.RESULT_MULTIPLIER )
    }
    var txAttrHomeTeam : NSAttributedString {
        return getAttrHome(txHomeTeam)
    }
    var txAttrAwayTeam : NSAttributedString {
        return getAttrAway(txAwayTeam)
    }
    var txAttrHomeResult : NSAttributedString {
        return getAttrHome(txHomeScore)
    }
    var txAttrAwayResult : NSAttributedString {
        return getAttrAway(txAwayScore)
    }
    
    func getEventDateForBet(bet: BetEntity) -> String  {
        return String.init(format: "BET %@ ", bet.outcome.description)
    }
    
    func getDescriptionForBet(bet: BetEntity) -> String  {
        var ret = ""
        switch bet.outcome  {
            case .MONEY_LINE_HOME_WIN, .SPREADS_HOME:
                ret = txHomeTeam
            case .MONEY_LINE_AWAY_WIN, .SPREADS_AWAY:
                ret = txAwayTeam
            case .MONEY_LINE_DRAW, .TOTAL_OVER, .TOTAL_UNDER:
                ret = String.init(format: "%@ - %@", txHomeTeam, txAwayTeam )
            case .UNKNOWN:
                ret = "Unknown"
        }
        return ret
    }
    
    private func getAttrHome(_ str : String ) -> NSAttributedString  {
        let homeAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.colorHome]
        let ret = NSMutableAttributedString(string: str, attributes: homeAttrs)
        return ret
    }
    private func getAttrAway(_ str : String ) -> NSAttributedString  {
        let awayAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.colorAway]
        let ret = NSMutableAttributedString(string: str, attributes: awayAttrs)
        return ret
    }
    
}
/*
class BetEventDetailViewModel : BetEventViewModel   {
    var currency : CurrencyDef
    
    init(_ betEvent : BetEventViewModel,_ currency : CurrencyDef)   {
        
    }
}
*/
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
    
    var description: String   {
        switch self     {
        case .MONEY_LINE_HOME_WIN:
            return "M. Line home"
        case .MONEY_LINE_AWAY_WIN:
            return "M. Line away"
        case .MONEY_LINE_DRAW:
            return "M. Line draw"
        case .SPREADS_HOME:
            return "Spreads home"
        case .SPREADS_AWAY:
            return "Spreads away"
        case .TOTAL_OVER:
            return "Totals Over"
        case .TOTAL_UNDER:
            return "Totals Under"
        case .UNKNOWN:
            return "Unknown"
        }
    }
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

enum BetTransactionType : Int32 {
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

