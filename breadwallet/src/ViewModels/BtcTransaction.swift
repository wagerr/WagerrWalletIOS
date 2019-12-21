//
//  BtcTransaction.swift
//  breadwallet
//
//  Created by Ehsan Rezaie on 2018-01-12.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import Foundation
import BRCore


struct WgrTransactionInfo {
    var transaction : BtcTransaction
    var betEntity : BetEntity?
    var betResult : BetResult?
    var betEvent : BetEventViewModel?
    var currentHeight : UInt32
    
    init(tx: BtcTransaction, ent: BetEntity?, res: BetResult?, event: BetEventViewModel?, currHeight: UInt32)  {
        self.transaction = tx
        self.betEntity = ent
        self.betResult = res
        self.betEvent = event
        self.currentHeight = currHeight
    }
    
    static func create(tx: BtcTransaction, wm: BTCWalletManager, callback: @escaping ( WgrTransactionInfo? ) -> Void  )   {
        var ent : BetEntity?
        var res : BetResult?
        var event : BetEventViewModel?
        let currHeight = wm.peerManager!.lastBlockHeight
        
        let opCodeManager = WagerrOpCodeManager();
        
        ent = opCodeManager.getEventIdFromCoreTx( (tx.getRawTransactionRef())  )
        if ent == nil {
            if tx.isCoinbase    {
                wm.db?.loadResultAtHeigh(blockHeight: Int(tx.blockHeight-1), callback: { result in
                    res = result
                    if result != nil    {
                        wm.db?.loadEvents( result!.eventID, 0, callback: { events in
                            event = events[0] ?? nil
                            callback( WgrTransactionInfo(tx: tx, ent: ent, res: res, event: event, currHeight: currHeight) )
                        })
                    }
                    else    {
                        callback( WgrTransactionInfo(tx: tx, ent: ent, res: res, event: event, currHeight: currHeight) )
                    }
                })
            }
            else    {
                callback( WgrTransactionInfo(tx: tx, ent: ent, res: res, event: event, currHeight: currHeight) )
            }
        }
        else    {
            wm.db?.loadEvents( ent!.eventID, 0, callback: { events in
                event = events[0] ?? nil
                callback( WgrTransactionInfo(tx: tx, ent: ent, res: res, event: event, currHeight: currHeight) )
            })
        }
    }
    
    var isCoinbase : Bool   {
        return transaction.isCoinbase
    }
    
    var isInmature : Bool   {
        return (self.currentHeight-UInt32(transaction.blockHeight)) <= W.Blockchain.payoutMaturity
    }
    
    var eventDateString : String {
        return (betEvent != nil) ? betEvent!.shortTimestamp : ""
    }
    
    var eventDetailString : String {
        return String.init(format: "%@ %@ - %@ %@", self.betEvent!.txHomeTeam, self.betEvent!.txHomeScore, self.betEvent!.txAwayScore, self.betEvent!.txAwayTeam)
    }
    
    func getDescriptionStrings() -> ( date: String, description: String) {
        var txDesc: String = ""
        var txDate: String = ""
        
        if self.betEntity == nil {
            if self.isCoinbase {   // payout
                if self.betResult != nil {
                    if self.betEvent != nil {
                        txDesc = String.init(format: "%@ - %@", self.betEvent!.txHomeTeam, self.betEvent!.txAwayTeam)
                    }
                    else {
                        txDesc = String.init(format: "Event #%d info not available", self.betEvent!.eventID)
                    }
                    txDate = String.init(format: "PAYOUT Event #%d", self.betEvent!.eventID)
                }
                else    {
                    txDesc = String.init(format: "Result not available at height %@", transaction.blockHeight)
                    txDate = "PAYOUT"
                }
                if isInmature {
                    txDate += String.init(format: "(%d/%d)", (self.currentHeight-UInt32(transaction.blockHeight)), W.Blockchain.payoutMaturity)
                }
            }
            else    {   // normal tx
                txDesc = ""
            }
        }
        else    {   // regular bet
            if self.betEvent != nil {
                txDesc = self.betEvent!.getDescriptionForBet(bet: self.betEntity!)
                txDate = self.betEvent!.getEventDateForBet(bet: self.betEntity!)
            }
            else {
                txDesc = String.init(format: "Event #%d info not available", self.betEntity!.eventID)
                txDate = String.init(format: "BET %@ ", self.betEntity!.outcome.description)
            }
        }
        return ( date: txDate, description: txDesc )
    }
}

/// Wrapper for BTC transaction model + metadata
struct BtcTransaction: Transaction {
    
    // MARK: Transaction Properties
    
    let currency: CurrencyDef
    let hash: String
    let status: TransactionStatus
    let direction: TransactionDirection
    let toAddress: String
    let timestamp: TimeInterval
    let blockHeight: UInt64
    let confirmations: UInt64
    let isValid: Bool
    let metaDataContainer: MetaDataContainer?
    let kvStore: BRReplicatedKVStore?
    
    // MARK: BTC-specific properties
    
    var rawTransaction: BRTransaction {
        return tx.pointee
    }
    
    func getRawTransactionRef() -> BRTxRef {
        return tx
    }
    
    var isCoinbase : Bool   {
        return tx.pointee.inCount==1 && tx.pointee.outCount>1 && tx.pointee.outputs[0].swiftAddress.isEmpty
    }
    
    let amount: UInt256
    let fee: UInt64
    let startingBalance: UInt64
    let endingBalance: UInt64
    
    // MARK: Private
    
    private let tx: BRTxRef
    
    // MARK: - Init
    
    init?(_ tx: BRTxRef, walletManager: BTCWalletManager, kvStore: BRReplicatedKVStore?, rate: Rate?) {
        guard let wallet = walletManager.wallet,
            let peerManager = walletManager.peerManager else { return nil }
        self.currency = walletManager.currency
        self.tx = tx
        self.kvStore = kvStore
        
        let amountReceived = wallet.amountReceivedFromTx(tx)
        let amountSent = wallet.amountSentByTx(tx)
        
        let fee = wallet.feeForTx(tx) ?? 0
        self.fee = fee
        
        // addresses from outputs
        let myAddress = tx.outputs.filter({ output in
            wallet.containsAddress(output.swiftAddress)
        }).first?.swiftAddress ?? ""
        let otherAddress = tx.outputs.filter({ output in
            !wallet.containsAddress(output.swiftAddress)
        }).first?.swiftAddress ?? ""
        
        // direction
        var direction: TransactionDirection
        if amountSent > 0 && (amountReceived + fee) == amountSent {
            direction = .moved
        } else if amountSent > 0 {
            direction = .sent
        } else {
            direction = .received
        }
        self.direction = direction
        
        let endingBalance: UInt64 = wallet.balanceAfterTx(tx)
        var startingBalance: UInt64
        var address: String
        var amount: UInt64
        switch direction {
        case .received:
            address = myAddress
            amount = amountReceived
            startingBalance = endingBalance.subtractingReportingOverflow(amount).0.subtractingReportingOverflow(fee).0
        case .sent:
            address = otherAddress
            amount = amountSent - amountReceived - fee
            startingBalance = endingBalance.addingReportingOverflow(amount).0.addingReportingOverflow(fee).0
        case .moved:
            address = myAddress
            amount = amountSent
            startingBalance = endingBalance.addingReportingOverflow(self.fee).0
        }
        self.amount = UInt256(amount)
        self.startingBalance = startingBalance
        self.endingBalance = endingBalance
        
        toAddress = currency.matches(Currencies.bch) ? address.bCashAddr : address
        
        hash = tx.pointee.txHash.description
        timestamp = TimeInterval(tx.pointee.timestamp)
        isValid = wallet.transactionIsValid(tx)
        blockHeight = (tx.pointee.blockHeight == UInt32.max) ? UInt64.max :  UInt64(tx.pointee.blockHeight)
        
        let lastBlockHeight = UInt64(peerManager.lastBlockHeight)
        confirmations = blockHeight > lastBlockHeight
            ? 0
            : (lastBlockHeight - blockHeight) + 1
        
        if isValid {
            switch confirmations {
            case 0:
                status = .pending
            case 1..<6:
                status = .confirmed
            default:
                status = .complete
            }
        } else {
            status = .invalid
        }
        
        // metadata
        if let kvStore = kvStore {
            metaDataContainer = MetaDataContainer(key: tx.pointee.txHash.txKey, kvStore: kvStore)
            if let rate = rate,
                confirmations < 6 && direction == .received {
                metaDataContainer!.createMetaData(tx: self, rate: rate)
            }
        } else {
            metaDataContainer = nil
        }
    }
}
