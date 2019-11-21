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
        var pos : Int = Int(OpcodesPosition.NAMESPACE + 1);
        let len : Int = (namespaceType == MappingNamespaceType.TEAM_NAME) ? 4 : 2;
        mappingID = getBuffer( Array( script[pos...pos+len]) );
        pos+=len;
        
        let description = String( bytes: Array(script[pos...end]), encoding: .isoLatin1 ) ?? "";
        mappingEntity = BetMapping(blockheight: UInt64(tx.blockHeight), timestamp: tx.timestamp, txHash: txHash, version: Int32(version), namespaceID: namespaceType, mappingID: mappingID, description: description );
        callback(mappingEntity);
    }
    
    func getBuffer(_ buf : [UInt8] ) -> UInt32 {
        assert( buf.count > MemoryLayout<UInt32>.size );
        var value : UInt32 = 0
        let data = NSData(bytes: buf, length: buf.count)
        data.getBytes(&value, length: buf.count)
        value = UInt32(littleEndian: value)
        return value;
    }
}
