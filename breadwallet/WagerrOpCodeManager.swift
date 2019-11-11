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
        //var betOutput : BRTxOutput
        tx.addOutput(amount: <#T##UInt64#>, script: <#T##[UInt8]#>)
        for output in tx.outputs    {
            let script = UnsafeMutableBufferPointer<UInt8>( start: output.script, count: output.scriptLen )
            if (script.count <= OpcodesPosition.BTX)   {    continue;   }
            
            let opcode = script[OpcodesPosition.OPCODE] & 0xFF;
            let test = script[OpcodesPosition.SMOKE_TEST] & 0xFF;
            if (opcode == OpcodeBytes.OP_RETURN && test == OpcodeBytes.SMOKE_TEST) {       // found wagerr bet tx!
                let type = script[OpcodesPosition.BTX] & 0xFF;
                let txType : BetTransactionType = BetTransactionType(rawValue: type)
                switch (txType) {
                    case .BET_PEERLESS:
                        ret = getPeerlessBet(tx, script, betAmount);
                        break;

                    case .BET_CHAIN_LOTTO:
                        ret = getChainGamesBetEntity(tx, script, betAmount);
                        break;
                }
            }
            return ret
        }
        
        
        return ret
    }

}
