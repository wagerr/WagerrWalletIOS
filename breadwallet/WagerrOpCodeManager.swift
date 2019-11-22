//
//  WagerrOpCodeManager.swift
//  breadwallet
//
//  Created by F.J. Ortiz on 10/11/2019.
//  Copyright © 2019 breadwallet LLC. All rights reserved.
//

import Foundation
import BRCore

private struct OpcodeBytes {
    static let OP_RETURN = 0x6a
    static let SMOKE_TEST = 0x42
}

private struct OpcodesPosition {
    static let OPCODE = 0
    static let LENGTH = 1
    static let SMOKE_TEST = 2
    static let VERSION = 3
    static let BTX = 4
    static let NAMESPACE = 5
    static let EVENTID = 5
}

private struct OpcodesLength {
    static let PEERLESS_LENGHT = 37
    static let RESULT_LENGHT = 10
    static let UPDATEODDS_LENGHT = 19
    static let SPREADS_LENGHT = 17
    static let TOTALS_LENGHT = 17
    static let PEERLESS_BET = 8
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

// buffer handler helper
private class PositionPointer   {
    private(set) var pos : Int;
    init(_ pos : Int )       {   self.pos = pos;}
    func Up(_ inc : Int )    {   self.pos += inc; }
}

class WagerrOpCodeManager   {
    
    func getEventIdFromCoreTx(_ tx : BRTxRef) -> BetEventDatabaseModel      {
        var ret : BetEventDatabaseModel
        let betAmount : Int64
        //var betOutput : BRTxOutput

        for output in tx.outputs    {
            let script = UnsafeMutableBufferPointer<UInt8>( start: output.script, count: output.scriptLen )
            if (script.count <= OpcodesPosition.BTX)   {    continue;   }
            
            let opcode = script[OpcodesPosition.OPCODE] & 0xFF;
            let test = script[OpcodesPosition.SMOKE_TEST] & 0xFF;
            if (opcode == OpcodeBytes.OP_RETURN && test == OpcodeBytes.SMOKE_TEST) {       // found wagerr bet tx!
                let type = script[OpcodesPosition.BTX] & 0xFF;
                let txType : BetTransactionType = BetTransactionType(rawValue: Int8(type))!
                switch (txType) {
                    case .BET_PEERLESS:
                        ret = getPeerlessBet(tx, script, betAmount);
                        break;

                    case .BET_CHAIN_LOTTO:
                        ret = getChainGamesBetEntity(tx, script, betAmount);
                        break;
                    
                    default:
                        break;
                }
            }
        }
        return ret
    }
    
    func decodeBetTransaction(_ tx : BRTxRef ) -> Bool {
        let isBetTx = false;
        
        for output in tx.outputs    {
            let script = UnsafeMutableBufferPointer<UInt8>( start: output.script, count: output.scriptLen )
            if (script.count <= OpcodesPosition.BTX)   {    continue;   }
            
            let opcode = script[OpcodesPosition.OPCODE] & 0xFF;
            let test = script[OpcodesPosition.SMOKE_TEST] & 0xFF;
            if (opcode == OpcodeBytes.OP_RETURN && test == OpcodeBytes.SMOKE_TEST) {       // found wagerr bet tx!
                let opLength = script[OpcodesPosition.LENGTH] & 0xFF;
                let type = script[OpcodesPosition.BTX] & 0xFF;
                let txType : BetTransactionType = BetTransactionType(rawValue: Int8(type))!
                switch (txType) {
                    case .MAPPING:
                        let betMappingEntity = getMappingEntity(tx, script);
                        break;

                    case .EVENT_PEERLESS:
                        let betEventEntity = getPeerlessEventEntity(tx, script);
                        break;

                    case .BET_PEERLESS:
                        betEntity = getPeerlessBet(tx, script, betAmount);
                        break;

                    case .RESULT_PEERLESS:
                        betResultEntity = getPeerlessResult(tx,script);
                        break;

                    case .UPDATE_PEERLESS:
                        betEventEntity = getPeerlessUpdateOddsEntity(tx, script);
                        updateEntity = true;
                        break;

                    case .EVENT_CHAIN_LOTTO:
                        betEventEntity = getChainGamesLottoEventEntity(tx, script);
                        break;

                    case .BET_CHAIN_LOTTO:
                        betEntity = getChainGamesBetEntity(tx, script, betAmount);
                        break;

                    case .RESULT_CHAIN_LOTTO:
                        betResultEntity = getChainGamesLottoResult(tx, script);

                    case .EVENT_PEERLESS_SPREAD:
                        betEventEntity = getPeerlessSpreadsMarket(tx, script);
                        break;

                    case .EVENT_PEERLESS_TOTAL:
                        betEventEntity = getPeerlessTotalsMarket(tx, script);
                        break;
                    
                    default:
                        break;
                }
            }
        }
        return isBetTx;
    }

    func getMappingEntity( tx : BRTxRef, script : UnsafeMutableBufferPointer<UInt8>, callback: @escaping (BetMapping?)->Void )
    {
        let mappingEntity : BetMapping?;
        
        let txHash : String = tx.txHash.description;
        let opLength = script[OpcodesPosition.LENGTH] & 0xFF;
        if (opLength < OpcodesPosition.NAMESPACE+2 )    {
            callback(nil);
        }
        let version = script[OpcodesPosition.VERSION] & 0xFF;   // ignore value so far
        let namespace = script[OpcodesPosition.NAMESPACE] & 0xFF;
        let namespaceType : MappingNamespaceType = MappingNamespaceType(rawValue: Int32(namespace))!
        if (namespaceType == MappingNamespaceType.UNKNOWN)  {
            callback(nil)
        }
        var mappingID : UInt32 = 0;
        let end : Int = Int(opLength+2);
        let pos = PositionPointer( Int(OpcodesPosition.NAMESPACE + 1) );
        let len : Int = (namespaceType == MappingNamespaceType.TEAM_NAME) ? 4 : 2;
        mappingID = getBuffer( script, pos, len );
        
        let description = String( bytes: Array(script[pos.pos...end]), encoding: .isoLatin1 ) ?? "";
        mappingEntity = BetMapping(blockheight: UInt64(tx.blockHeight), timestamp: tx.timestamp, txHash: txHash, version: UInt32(version), namespaceID: namespaceType, mappingID: mappingID, description: description );
        callback(mappingEntity);
    }
    
    func getPeerlessEventEntity( tx : BRTxRef, script : UnsafeMutableBufferPointer<UInt8>, callback: @escaping (BetEventDatabaseModel?)->Void )
    {
        let betEntity : BetEventDatabaseModel?;
        
        let txHash : String = tx.txHash.description;
        let opLength = script[OpcodesPosition.LENGTH] & 0xFF;
        if (opLength < OpcodesLength.PEERLESS_LENGHT )    {
            callback(nil);
        }
        let version = script[OpcodesPosition.VERSION] & 0xFF;   // ignore value so far
        let pos = PositionPointer( Int(OpcodesPosition.EVENTID) );
        let eventID = getBuffer( script, pos );
        let eventTimestamp = Time(getBuffer( script, pos ));
        let sportID = getBuffer( script, pos);
        let tournamentID = getBuffer( script, pos);
        let roundID = getBuffer( script, pos);
        let homeTeamID = getBuffer( script, pos);
        let awayTeamID = getBuffer( script, pos);
        let homeOdds = getBuffer( script, pos);
        let awayOdds = getBuffer( script, pos);
        let drawOdds = getBuffer( script, pos);
        
        betEntity = BetEventDatabaseModel(blockheight: UInt64(tx.blockHeight), timestamp: tx.timestamp, lastUpdated: tx.timestamp, txHash: txHash, version: UInt32(version), type: BetTransactionType.EVENT_PEERLESS, eventID: UInt64(eventID), eventTimestamp: eventTimestamp, sportID: sportID, tournamentID: tournamentID, roundID: roundID, homeTeamID: homeTeamID, awayTeamID: awayTeamID, homeOdds: homeOdds, awayOdds: awayOdds, drawOdds: drawOdds, entryPrice: 0, spreadPoints: 0, spreadHomeOdds: 0, spreadAwayOdds: 0, totalPoints: 0, overOdds: 0, underOdds: 0 );
        callback(betEntity);
    }
    
    func getPeerlessResult( tx : BRTxRef, script : UnsafeMutableBufferPointer<UInt8>, callback: @escaping (BetResult?)->Void )
    {
        let betResult : BetResult?;
        
        let txHash : String = tx.txHash.description;
        let opLength = script[OpcodesPosition.LENGTH] & 0xFF;
        if (opLength < OpcodesLength.RESULT_LENGHT )    {
            callback(nil);
        }
        let version = script[OpcodesPosition.VERSION] & 0xFF;   // ignore value so far
        let pos = PositionPointer( Int(OpcodesPosition.EVENTID) );
        let eventID = getBuffer( script, pos );
        let resultType = BetResultType(rawValue: Int32(script[pos.pos]))!;
        pos.Up(1);
        let homeTeamScore = getBuffer( script, pos, 2);
        let awayTeamScore = getBuffer( script, pos, 2);
        
        betResult = BetResult(blockheight: UInt64(tx.blockHeight), timestamp: tx.timestamp, txHash: txHash, version: UInt32(version), type: BetTransactionType.RESULT_PEERLESS, eventID: UInt64(eventID), resultType: resultType, homeScore: homeTeamScore, awayScore: awayTeamScore );
        callback(betResult);
    }
    
    func getPeerlessBet( tx : BRTxRef, script : UnsafeMutableBufferPointer<UInt8>, amount: UInt64, callback: @escaping (BetEntity?)->Void )
    {
        let betEntity : BetEntity;
        
        let txHash : String = tx.txHash.description;
        let opLength = script[OpcodesPosition.LENGTH] & 0xFF;
        if (opLength < OpcodesLength.PEERLESS_BET )    {
            callback(nil);
        }
        let version = script[OpcodesPosition.VERSION] & 0xFF;   // ignore value so far
        let pos = PositionPointer( Int(OpcodesPosition.EVENTID) );
        let eventID = getBuffer( script, pos );
        let outcome = BetOutcome(rawValue: Int32(script[pos.pos]))!;
        
        betEntity = BetEntity(blockheight: UInt64(tx.blockHeight), timestamp: tx.timestamp, txHash: txHash, version: UInt32(version), type: BetType.PEERLESS, eventID: UInt64(eventID), outcome: outcome, amount: amount );
        callback(betEntity);
    }
    
    func getUpdateOdds( tx : BRTxRef, script : UnsafeMutableBufferPointer<UInt8>, callback: @escaping (BetEventDatabaseModel?)->Void )
    {
        let betEntity : BetEventDatabaseModel?;
        
        let txHash : String = tx.txHash.description;
        let opLength = script[OpcodesPosition.LENGTH] & 0xFF;
        if (opLength < OpcodesLength.UPDATEODDS_LENGHT )    {
            callback(nil);
        }
        let version = script[OpcodesPosition.VERSION] & 0xFF;   // ignore value so far
        let pos = PositionPointer( Int(OpcodesPosition.EVENTID) );
        let eventID = getBuffer( script, pos );
        let homeOdds = getBuffer( script, pos);
        let awayOdds = getBuffer( script, pos);
        let drawOdds = getBuffer( script, pos);
        
        betEntity = BetEventDatabaseModel(blockheight: UInt64(tx.blockHeight), timestamp: tx.timestamp, lastUpdated: tx.timestamp, txHash: txHash, version: UInt32(version), type: BetTransactionType.UPDATE_PEERLESS, eventID: UInt64(eventID), eventTimestamp: 0, sportID: 0, tournamentID: 0, roundID: 0, homeTeamID: 0, awayTeamID: 0, homeOdds: homeOdds, awayOdds: awayOdds, drawOdds: drawOdds, entryPrice: 0, spreadPoints: 0, spreadHomeOdds: 0, spreadAwayOdds: 0, totalPoints: 0, overOdds: 0, underOdds: 0 );
        callback(betEntity);
    }
    
    func getSpreadsMarkets( tx : BRTxRef, script : UnsafeMutableBufferPointer<UInt8>, callback: @escaping (BetEventDatabaseModel?)->Void )
    {
        let betEntity : BetEventDatabaseModel?;
        
        let txHash : String = tx.txHash.description;
        let opLength = script[OpcodesPosition.LENGTH] & 0xFF;
        if (opLength < OpcodesLength.SPREADS_LENGHT )    {
            callback(nil);
        }
        let version = script[OpcodesPosition.VERSION] & 0xFF;   // ignore value so far
        let pos = PositionPointer( Int(OpcodesPosition.EVENTID) );
        let eventID = getBuffer( script, pos );
        let spreadPoints = getBuffer( script, pos, 2 );
        let homeOdds = getBuffer( script, pos);
        let awayOdds = getBuffer( script, pos);
        
        betEntity = BetEventDatabaseModel(blockheight: UInt64(tx.blockHeight), timestamp: tx.timestamp, lastUpdated: tx.timestamp, txHash: txHash, version: UInt32(version), type: BetTransactionType.EVENT_PEERLESS_SPREAD, eventID: UInt64(eventID), eventTimestamp: 0, sportID: 0, tournamentID: 0, roundID: 0, homeTeamID: 0, awayTeamID: 0, homeOdds: 0, awayOdds: 0, drawOdds: 0, entryPrice: 0, spreadPoints: spreadPoints, spreadHomeOdds: homeOdds, spreadAwayOdds: awayOdds, totalPoints: 0, overOdds: 0, underOdds: 0 );
        callback(betEntity);
    }
    
    func getTotalsMarkets( tx : BRTxRef, script : UnsafeMutableBufferPointer<UInt8>, callback: @escaping (BetEventDatabaseModel?)->Void )
    {
        let betEntity : BetEventDatabaseModel?;
        
        let txHash : String = tx.txHash.description;
        let opLength = script[OpcodesPosition.LENGTH] & 0xFF;
        if (opLength < OpcodesLength.TOTALS_LENGHT )    {
            callback(nil);
        }
        let version = script[OpcodesPosition.VERSION] & 0xFF;   // ignore value so far
        let pos = PositionPointer( Int(OpcodesPosition.EVENTID) );
        let eventID = getBuffer( script, pos );
        let totalPoints = getBuffer( script, pos, 2);
        let overOdds = getBuffer( script, pos);
        let underOdds = getBuffer( script, pos);
        
        betEntity = BetEventDatabaseModel(blockheight: UInt64(tx.blockHeight), timestamp: tx.timestamp, lastUpdated: tx.timestamp, txHash: txHash, version: UInt32(version), type: BetTransactionType.EVENT_PEERLESS, eventID: UInt64(eventID), eventTimestamp: 0, sportID: 0, tournamentID: 0, roundID: 0, homeTeamID: 0, awayTeamID: 0, homeOdds: 0, awayOdds: 0, drawOdds: 0, entryPrice: 0, spreadPoints: 0, spreadHomeOdds: 0, spreadAwayOdds: 0, totalPoints: totalPoints, overOdds: overOdds, underOdds: underOdds );
        callback(betEntity);
    }
    

    func Time(_ t : UInt32 ) -> TimeInterval {
        return (t > UInt32(NSTimeIntervalSince1970)) ? TimeInterval(t - UInt32(NSTimeIntervalSince1970)) : 0
    }
    
    fileprivate func getBuffer(_ script : UnsafeMutableBufferPointer<UInt8>,_ pos : PositionPointer,_ len : Int = 4 ) -> UInt32 {
        let buf = Array( script[pos.pos...pos.pos+len]);
        assert( buf.count > MemoryLayout<UInt32>.size );
        var value : UInt32 = 0;
        let data = NSData(bytes: buf, length: buf.count);
        data.getBytes(&value, length: buf.count);
        value = UInt32(littleEndian: value);
        pos.Up(buf.count);
        return value;
    }
}
