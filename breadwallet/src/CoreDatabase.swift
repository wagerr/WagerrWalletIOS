//
//  Database.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-11-10.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import Foundation
import BRCore
import sqlite3

internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
internal let SQLITE_MAX_LENGTH = 1000000000
internal let FLAGSLEN_MAX = 1000

extension String {
    public init?(validatingUTF8 cString: UnsafePointer<UInt8>) {
        guard let (s, _) = String.decodeCString(cString, as: UTF8.self,
                                                repairingInvalidCodeUnits: false) else {
            return nil
        }
        self = s
    }
}

enum WalletManagerError: Error {
    case sqliteError(errorCode: Int32, description: String)
}

private func SafeSqlite3ColumnBlob<T>(statement: OpaquePointer, iCol: Int32) -> UnsafePointer<T>? {
    guard let result = sqlite3_column_blob(statement, iCol) else { return nil }
    return result.assumingMemoryBound(to: T.self)
}

class CoreDatabase {

    private let dbPath: String
    private var db: OpaquePointer? = nil
    private var txEnt: Int32 = 0
    private var blockEnt: Int32 = 0
    private var peerEnt: Int32 = 0
    private var mappingEnt: Int32 = 0
    private var eventEnt: Int32 = 0
    private var resultEnt: Int32 = 0
    private let queue = DispatchQueue(label: "com.wagerrwallet.corecbqueue")

    init(dbPath: String = "BreadWallet.sqlite") {
        self.dbPath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil,
                                    create: false).appendingPathComponent(dbPath).path
        queue.async {
            try? self.openDatabase()
        }
    }

    deinit {
        if db != nil { sqlite3_close(db) }
    }

    func close() {
        if db != nil { sqlite3_close(db) }
    }

    func delete() {
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    private func openDatabase() throws {
        // open sqlite database
        if sqlite3_open_v2( self.dbPath, &db,
                            SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil
            ) != SQLITE_OK {
            print(String(cString: sqlite3_errmsg(db)))

            #if DEBUG
                throw WalletManagerError.sqliteError(errorCode: sqlite3_errcode(db),
                                                     description: String(cString: sqlite3_errmsg(db)))
            #else
                try FileManager.default.removeItem(atPath: self.dbPath)

                if sqlite3_open_v2( self.dbPath, &db,
                                    SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil
                    ) != SQLITE_OK {
                    throw WalletManagerError.sqliteError(errorCode: sqlite3_errcode(db),
                                                         description: String(cString: sqlite3_errmsg(db)))
                }
            #endif
        }

        // create tables and indexes (these are inherited from CoreData)

        // tx table
        sqlite3_exec(db, "create table if not exists ZBRTXMETADATAENTITY (" +
            "Z_PK integer primary key," +
            "Z_ENT integer," +
            "Z_OPT integer," +
            "ZTYPE integer," +
            "ZBLOB blob," +
            "ZTXHASH blob)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRTXMETADATAENTITY_ZTXHASH_INDEX " +
            "on ZBRTXMETADATAENTITY (ZTXHASH)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRTXMETADATAENTITY_ZTYPE_INDEX " +
            "on ZBRTXMETADATAENTITY (ZTYPE)", nil, nil, nil)
        if sqlite3_errcode(db) != SQLITE_OK { print(String(cString: sqlite3_errmsg(db))) }

        // blocks table
        sqlite3_exec(db, "create table if not exists ZBRMERKLEBLOCKENTITY (" +
            "Z_PK integer primary key," +
            "Z_ENT integer," +
            "Z_OPT integer," +
            "ZHEIGHT integer," +
            "ZNONCE integer," +
            "ZTARGET integer," +
            "ZTOTALTRANSACTIONS integer," +
            "ZVERSION integer," +
            "ZTIMESTAMP timestamp," +
            "ZBLOCKHASH blob," +
            "ZFLAGS blob," +
            "ZHASHES blob," +
            "ZMERKLEROOT blob," +
            "ZPREVBLOCK blob)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRMERKLEBLOCKENTITY_ZBLOCKHASH_INDEX " +
            "on ZBRMERKLEBLOCKENTITY (ZBLOCKHASH)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRMERKLEBLOCKENTITY_ZHEIGHT_INDEX " +
            "on ZBRMERKLEBLOCKENTITY (ZHEIGHT)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRMERKLEBLOCKENTITY_ZPREVBLOCK_INDEX " +
            "on ZBRMERKLEBLOCKENTITY (ZPREVBLOCK)", nil, nil, nil)
        if sqlite3_errcode(db) != SQLITE_OK { print(String(cString: sqlite3_errmsg(db))) }

        // peers table
        sqlite3_exec(db, "create table if not exists ZBRPEERENTITY (" +
            "Z_PK integer PRIMARY KEY," +
            "Z_ENT integer," +
            "Z_OPT integer," +
            "ZADDRESS integer," +
            "ZMISBEHAVIN integer," +
            "ZPORT integer," +
            "ZSERVICES integer," +
            "ZTIMESTAMP timestamp)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRPEERENTITY_ZADDRESS_INDEX on ZBRPEERENTITY (ZADDRESS)",
                     nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRPEERENTITY_ZMISBEHAVIN_INDEX on ZBRPEERENTITY (ZMISBEHAVIN)",
                     nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRPEERENTITY_ZPORT_INDEX on ZBRPEERENTITY (ZPORT)",
                     nil, nil, nil)
        sqlite3_exec(db, "create index if not exists ZBRPEERENTITY_ZTIMESTAMP_INDEX on ZBRPEERENTITY (ZTIMESTAMP)",
                     nil, nil, nil)
        if sqlite3_errcode(db) != SQLITE_OK { print(String(cString: sqlite3_errmsg(db))) }

        /* Wagerr Betting transaction tables
            WGR_MAPPING
            WGR_EVENT
            WGR_RESULT
         
         */
        // WGR_MAPPING
        sqlite3_exec(db, "create table if not exists WGR_MAPPING (" +
            "Z_PK integer primary key," +
            "ZVERSION integer," +
            "ZNAMESPACEID integer," +
            "ZMAPPINGID integer," +
            "ZSTRING varchar," +
            
            "ZTIMESTAMP integer," +
            "ZHEIGHT integer," +
            "ZTXHASH varchar)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists WGR_MAPPING_ZTXHASH_INDEX " +
            "on WGR_MAPPING (ZTXHASH)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists WGR_MAPPING_ZNAMESPACEID_INDEX " +
            "on WGR_MAPPING (ZNAMESPACEID)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists WGR_MAPPING_ZMAPPINGID_INDEX " +
            "on WGR_MAPPING (ZMAPPINGID)", nil, nil, nil)
        if sqlite3_errcode(db) != SQLITE_OK { print(String(cString: sqlite3_errmsg(db))) }
        
        // WGR_EVENT
        sqlite3_exec(db, "create table if not exists WGR_EVENT (" +
            "Z_PK integer primary key," +
            "ZTYPE integer," +
            "ZVERSION integer," +
            "ZEVENT_ID integer," +
            "ZEVENT_TIMESTAMP integer," +
            "ZSPORT_ID integer," +
            "ZTOURNAMENT_ID integer," +
            "ZROUND_ID integer," +
            "ZHOME_TEAM integer," +
            "ZAWAY_TEAM integer," +
            "ZHOME_ODDS integer," +
            "ZAWAY_ODDS integer," +
            "ZDRAW_ODDS integer," +
            "ZENTRY_PRICE integer," +
            "ZSPREAD_POINTS integer," +
            "ZSPREAD_HOME_ODDS integer," +
            "ZSPREAD_AWAY_ODDS integer," +
            "ZTOTAL_POINTS integer," +
            "ZTOTAL_OVER_ODDS integer," +
            "ZTOTAL_UNDER_ODDS integer," +

            "ZLAST_UPDATED integer," +
            "ZTIMESTAMP integer," +
            "ZHEIGHT integer," +
            "ZTXHASH varchar)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists WGR_EVENT_ZTXHASH_INDEX " +
            "on WGR_EVENT(ZTXHASH)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists WGR_EVENT_ZEVENT_ID_INDEX " +
            "on WGR_EVENT (ZEVENT_ID)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists WGR_EVENT_ZEVENT_TIMESTAMP_INDEX " +
            "on WGR_EVENT (ZEVENT_TIMESTAMP)", nil, nil, nil)
        if sqlite3_errcode(db) != SQLITE_OK { print(String(cString: sqlite3_errmsg(db))) }
        
        // WGR_RESULT
        sqlite3_exec(db, "create table if not exists WGR_RESULT (" +
            "Z_PK integer primary key," +
            "ZTYPE integer," +
            "ZVERSION integer," +
            "ZEVENT_ID integer," +
            "ZRESULT_TYPE integer," +
            "ZHOME_TEAM_SCORE integer," +
            "ZAWAY_TEAM_SCORE integer," +

            "ZTIMESTAMP integer," +
            "ZHEIGHT integer," +
            "ZTXHASH varchar)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists WGR_RESULT_ZTXHASH_INDEX " +
            "on WGR_RESULT (ZTXHASH)", nil, nil, nil)
        sqlite3_exec(db, "create index if not exists WGR_RESULT_ZEVENT_ID_INDEX " +
            "on WGR_RESULT (ZEVENT_ID)", nil, nil, nil)
        if sqlite3_errcode(db) != SQLITE_OK { print(String(cString: sqlite3_errmsg(db))) }
        
        // End WAGERR tables
        
        // primary keys
        sqlite3_exec(db, "create table if not exists Z_PRIMARYKEY (" +
            "Z_ENT INTEGER PRIMARY KEY," +
            "Z_NAME VARCHAR," +
            "Z_SUPER INTEGER," +
            "Z_MAX INTEGER)", nil, nil, nil)
        sqlite3_exec(db, "insert into Z_PRIMARYKEY (Z_ENT, Z_NAME, Z_SUPER, Z_MAX) " +
            "select 6, 'BRTxMetadataEntity', 0, 0 except " +
            "select 6, Z_NAME, 0, 0 from Z_PRIMARYKEY where Z_NAME = 'BRTxMetadataEntity'", nil, nil, nil)
        sqlite3_exec(db, "insert into Z_PRIMARYKEY (Z_ENT, Z_NAME, Z_SUPER, Z_MAX) " +
            "select 2, 'BRMerkleBlockEntity', 0, 0 except " +
            "select 2, Z_NAME, 0, 0 from Z_PRIMARYKEY where Z_NAME = 'BRMerkleBlockEntity'", nil, nil, nil)
        sqlite3_exec(db, "insert into Z_PRIMARYKEY (Z_ENT, Z_NAME, Z_SUPER, Z_MAX) " +
            "select 3, 'BRPeerEntity', 0, 0 except " +
            "select 3, Z_NAME, 0, 0 from Z_PRIMARYKEY where Z_NAME = 'BRPeerEntity'", nil, nil, nil)

        // Start WAGERR PKa
        sqlite3_exec(db, "insert into Z_PRIMARYKEY (Z_ENT, Z_NAME, Z_SUPER, Z_MAX) " +
            "select 10, 'WGR_Mapping', 0, 0 except " +
            "select 10, Z_NAME, 0, 0 from Z_PRIMARYKEY where Z_NAME = 'WGR_Mapping'", nil, nil, nil)
        sqlite3_exec(db, "insert into Z_PRIMARYKEY (Z_ENT, Z_NAME, Z_SUPER, Z_MAX) " +
            "select 11, 'WGR_Event', 0, 0 except " +
            "select 11, Z_NAME, 0, 0 from Z_PRIMARYKEY where Z_NAME = 'WGR_Event'", nil, nil, nil)
        sqlite3_exec(db, "insert into Z_PRIMARYKEY (Z_ENT, Z_NAME, Z_SUPER, Z_MAX) " +
            "select 12, 'WGR_Result', 0, 0 except " +
            "select 12, Z_NAME, 0, 0 from Z_PRIMARYKEY where Z_NAME = 'WGR_Result'", nil, nil, nil)
        // End WAGERR PKs

        if sqlite3_errcode(db) != SQLITE_OK { print(String(cString: sqlite3_errmsg(db))) }

        var sql: OpaquePointer? = nil
        sqlite3_prepare_v2(db, "select Z_ENT, Z_NAME from Z_PRIMARYKEY", -1, &sql, nil)
        defer { sqlite3_finalize(sql) }

        while sqlite3_step(sql) == SQLITE_ROW {
            let name = String(cString: sqlite3_column_text(sql, 1))
            if name == "BRTxMetadataEntity" { txEnt = sqlite3_column_int(sql, 0) }
            else if name == "BRMerkleBlockEntity" { blockEnt = sqlite3_column_int(sql, 0) }
            else if name == "BRPeerEntity" { peerEnt = sqlite3_column_int(sql, 0) }
            else if name == "WGR_Mapping" { mappingEnt = sqlite3_column_int(sql, 0) }
            else if name == "WGR_Event" { eventEnt = sqlite3_column_int(sql, 0) }
            else if name == "WGR_Result" { resultEnt = sqlite3_column_int(sql, 0) }
        }

        if sqlite3_errcode(db) != SQLITE_DONE { print(String(cString: sqlite3_errmsg(db))) }
    }

    func txAdded(_ tx: BRTxRef) {
        queue.async {
            var buf = [UInt8](repeating: 0, count: BRTransactionSerialize(tx, nil, 0))
            let timestamp = (tx.pointee.timestamp > UInt32(NSTimeIntervalSince1970)) ? tx.pointee.timestamp - UInt32(NSTimeIntervalSince1970) : 0
            guard BRTransactionSerialize(tx, &buf, buf.count) == buf.count else { return }
            [tx.pointee.blockHeight.littleEndian, timestamp.littleEndian].withUnsafeBytes { buf.append(contentsOf: $0) }
            sqlite3_exec(self.db, "begin exclusive", nil, nil, nil)

            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select Z_MAX from Z_PRIMARYKEY where Z_ENT = \(self.txEnt)", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }

            guard sqlite3_step(sql) == SQLITE_ROW else {
                print(String(cString: sqlite3_errmsg(self.db)))
                sqlite3_exec(self.db, "rollback", nil, nil, nil)
                return
            }

            let pk = sqlite3_column_int(sql, 0)
            var sql2: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "insert or rollback into ZBRTXMETADATAENTITY " +
                "(Z_PK, Z_ENT, Z_OPT, ZTYPE, ZBLOB, ZTXHASH) " +
                "values (\(pk + 1), \(self.txEnt), 1, 1, ?, ?)", -1, &sql2, nil)
            defer { sqlite3_finalize(sql2) }
            sqlite3_bind_blob(sql2, 1, buf, Int32(buf.count), SQLITE_TRANSIENT)
            sqlite3_bind_blob(sql2, 2, [tx.pointee.txHash], Int32(MemoryLayout<UInt256>.size), SQLITE_TRANSIENT)

            guard sqlite3_step(sql2) == SQLITE_DONE else {
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }

            sqlite3_exec(self.db, "update or rollback Z_PRIMARYKEY set Z_MAX = \(pk + 1) " +
                "where Z_ENT = \(self.txEnt) and Z_MAX = \(pk)", nil, nil, nil)

            guard sqlite3_errcode(self.db) == SQLITE_OK else {
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }

            sqlite3_exec(self.db, "commit", nil, nil, nil)
            self.setDBFileAttributes()
        }
    }

    func setDBFileAttributes() {
        queue.async {
            let files = [self.dbPath, self.dbPath + "-shm", self.dbPath + "-wal"]
            files.forEach {
                if FileManager.default.fileExists(atPath: $0) {
                    do {
                        try FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: $0)
                    } catch let e {
                        print("Set db attributes error: \(e)")
                    }
                }
            }
        }
    }

    func txUpdated(_ txHashes: [UInt256], blockHeight: UInt32, timestamp: UInt32) {
        queue.async {
            guard txHashes.count > 0 else { return }
            let timestamp = (timestamp > UInt32(NSTimeIntervalSince1970)) ? timestamp - UInt32(NSTimeIntervalSince1970) : 0
            var sql: OpaquePointer? = nil, sql2: OpaquePointer? = nil, count = 0
            sqlite3_prepare_v2(self.db, "select ZTXHASH, ZBLOB from ZBRTXMETADATAENTITY where ZTYPE = 1 and " +
                "ZTXHASH in (" + String(repeating: "?, ", count: txHashes.count - 1) + "?)", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }

            for i in 0..<txHashes.count {
                sqlite3_bind_blob(sql, Int32(i + 1), [txHashes[i]], Int32(MemoryLayout<UInt256>.size), SQLITE_TRANSIENT)
            }

            sqlite3_prepare_v2(self.db, "update ZBRTXMETADATAENTITY set ZBLOB = ? where ZTXHASH = ?", -1, &sql2, nil)
            defer { sqlite3_finalize(sql2) }

            while sqlite3_step(sql) == SQLITE_ROW {
                let hash = sqlite3_column_blob(sql, 0)
                let buf = sqlite3_column_blob(sql, 1).assumingMemoryBound(to: UInt8.self)
                var blob = [UInt8](UnsafeBufferPointer(start: buf, count: Int(sqlite3_column_bytes(sql, 1))))

                [blockHeight.littleEndian, timestamp.littleEndian].withUnsafeBytes {
                    if blob.count > $0.count {
                        blob.replaceSubrange(blob.count - $0.count..<blob.count, with: $0)
                        sqlite3_bind_blob(sql2, 1, blob, Int32(blob.count), SQLITE_TRANSIENT)
                        sqlite3_bind_blob(sql2, 2, hash, Int32(MemoryLayout<UInt256>.size), SQLITE_TRANSIENT)
                        sqlite3_step(sql2)
                        sqlite3_reset(sql2)
                    }
                }
                
                count = count + 1
            }

            if sqlite3_errcode(self.db) != SQLITE_DONE { print(String(cString: sqlite3_errmsg(self.db))) }

            if count != txHashes.count {
                print("Fewer tx records updated than hashes! This causes tx to go missing!")
                exit(0) // DIE! DIE! DIE!
            }
        }
    }

    func txDeleted(_ txHash: UInt256, notifyUser: Bool, recommendRescan: Bool) {
        queue.async {
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "delete from ZBRTXMETADATAENTITY where ZTYPE = 1 and ZTXHASH = ?", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            sqlite3_bind_blob(sql, 1, [txHash], Int32(MemoryLayout<UInt256>.size), SQLITE_TRANSIENT)

            guard sqlite3_step(sql) == SQLITE_DONE else {
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }
        }
    }

    func saveBlocks(_ replace: Bool, _ blocks: [BRBlockRef?]) {
        queue.async {
            var pk: Int32 = 0
            sqlite3_exec(self.db, "begin exclusive", nil, nil, nil)

            if replace { // delete existing blocks and replace
                sqlite3_exec(self.db, "delete from ZBRMERKLEBLOCKENTITY", nil, nil, nil)
            }
            else { // add to existing blocks
                var sql: OpaquePointer? = nil
                sqlite3_prepare_v2(self.db, "select Z_MAX from Z_PRIMARYKEY where Z_ENT = \(self.blockEnt)", -1, &sql, nil)
                defer { sqlite3_finalize(sql) }

                guard sqlite3_step(sql) == SQLITE_ROW else {
                    print(String(cString: sqlite3_errmsg(self.db)))
                    sqlite3_exec(self.db, "rollback", nil, nil, nil)
                    return
                }

                pk = sqlite3_column_int(sql, 0) // get last primary key
            }

            var sql2: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "insert or rollback into ZBRMERKLEBLOCKENTITY (Z_PK, Z_ENT, Z_OPT, ZHEIGHT, " +
                "ZNONCE, ZTARGET, ZTOTALTRANSACTIONS, ZVERSION, ZTIMESTAMP, ZBLOCKHASH, ZFLAGS, ZHASHES, " +
                "ZMERKLEROOT, ZPREVBLOCK) values (?, \(self.blockEnt), 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", -1, &sql2, nil)
            defer { sqlite3_finalize(sql2) }

            for b in blocks {
                guard let b = b else {
                    sqlite3_exec(self.db, "rollback", nil, nil, nil)
                    return
                }

                let timestampResult = Int32(bitPattern: b.pointee.timestamp).subtractingReportingOverflow(Int32(NSTimeIntervalSince1970))
                guard !timestampResult.1 else { print("skipped block with overflowed timestamp"); continue }

                pk = pk + 1
                sqlite3_bind_int(sql2, 1, pk)
                sqlite3_bind_int(sql2, 2, Int32(bitPattern: b.pointee.height))
                sqlite3_bind_int(sql2, 3, Int32(bitPattern: b.pointee.nonce))
                sqlite3_bind_int(sql2, 4, Int32(bitPattern: b.pointee.target))
                sqlite3_bind_int(sql2, 5, Int32(bitPattern: b.pointee.totalTx))
                sqlite3_bind_int(sql2, 6, Int32(bitPattern: b.pointee.version))
                sqlite3_bind_int(sql2, 7, timestampResult.0)
                sqlite3_bind_blob(sql2, 8, [b.pointee.blockHash], Int32(MemoryLayout<UInt256>.size), SQLITE_TRANSIENT)
                // faulty clients send corrupted flagLen number and crash the wallet, fall back to 1...
                sqlite3_bind_blob(sql2, 9, [b.pointee.flags], Int32(b.pointee.flagsLen) < FLAGSLEN_MAX ? Int32(b.pointee.flagsLen):1, SQLITE_TRANSIENT)
                // protect from corrupted blocks
                if b.pointee.hashesCount > 10000    {   
                    continue
                }
                sqlite3_bind_blob(sql2, 10, [b.pointee.hashes], Int32(MemoryLayout<UInt256>.size*b.pointee.hashesCount),
                                  SQLITE_TRANSIENT)
                sqlite3_bind_blob(sql2, 11, [b.pointee.merkleRoot], Int32(MemoryLayout<UInt256>.size), SQLITE_TRANSIENT)
                sqlite3_bind_blob(sql2, 12, [b.pointee.prevBlock], Int32(MemoryLayout<UInt256>.size), SQLITE_TRANSIENT)

                guard sqlite3_step(sql2) == SQLITE_DONE else {
                    print(String(cString: sqlite3_errmsg(self.db)))
                    return
                }

                sqlite3_reset(sql2)
            }

            sqlite3_exec(self.db, "update or rollback Z_PRIMARYKEY set Z_MAX = \(pk) where Z_ENT = \(self.blockEnt)",
                nil, nil, nil)

            guard sqlite3_errcode(self.db) == SQLITE_OK else {
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }

            sqlite3_exec(self.db, "commit", nil, nil, nil)
        }
    }

    func savePeers(_ replace: Bool, _ peers: [BRPeer]) {
        queue.async {
            var pk: Int32 = 0
            sqlite3_exec(self.db, "begin exclusive", nil, nil, nil)

            if replace { // delete existing peers and replace
                sqlite3_exec(self.db, "delete from ZBRPEERENTITY", nil, nil, nil)
            }
            else { // add to existing peers
                var sql: OpaquePointer? = nil
                sqlite3_prepare_v2(self.db, "select Z_MAX from Z_PRIMARYKEY where Z_ENT = \(self.peerEnt)", -1, &sql, nil)
                defer { sqlite3_finalize(sql) }

                guard sqlite3_step(sql) == SQLITE_ROW else {
                    print(String(cString: sqlite3_errmsg(self.db)))
                    sqlite3_exec(self.db, "rollback", nil, nil, nil)
                    return
                }

                pk = sqlite3_column_int(sql, 0) // get last primary key
            }

            var sql2: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "insert or rollback into ZBRPEERENTITY " +
                "(Z_PK, Z_ENT, Z_OPT, ZADDRESS, ZMISBEHAVIN, ZPORT, ZSERVICES, ZTIMESTAMP) " +
                "values (?, \(self.peerEnt), 1, ?, 0, ?, ?, ?)", -1, &sql2, nil)
            defer { sqlite3_finalize(sql2) }

            for p in peers {
                pk = pk + 1
                sqlite3_bind_int(sql2, 1, pk)
                sqlite3_bind_int(sql2, 2, Int32(bitPattern: p.address.u32.3.bigEndian))
                sqlite3_bind_int(sql2, 3, Int32(p.port))
                sqlite3_bind_int64(sql2, 4, Int64(bitPattern: p.services))
                sqlite3_bind_int64(sql2, 5, Int64(bitPattern: p.timestamp) - Int64(NSTimeIntervalSince1970))

                guard sqlite3_step(sql2) == SQLITE_DONE else {
                    print(String(cString: sqlite3_errmsg(self.db)))
                    return
                }

                sqlite3_reset(sql2)
            }

            sqlite3_exec(self.db, "update or rollback Z_PRIMARYKEY set Z_MAX = \(pk) where Z_ENT = \(self.peerEnt)",
                nil, nil, nil)

            guard sqlite3_errcode(self.db) == SQLITE_OK else {
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }

            sqlite3_exec(self.db, "commit", nil, nil, nil)
        }
    }


    func loadTransactions(callback: @escaping ([BRTxRef?])->Void) {
        queue.async {
            var transactions = [BRTxRef?]()
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select ZBLOB from ZBRTXMETADATAENTITY where ZTYPE = 1", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }

            while sqlite3_step(sql) == SQLITE_ROW {
                let len = Int(sqlite3_column_bytes(sql, 0))
                let buf = sqlite3_column_blob(sql, 0).assumingMemoryBound(to: UInt8.self)
                guard len >= MemoryLayout<UInt32>.size*2 else { return DispatchQueue.main.async { callback(transactions) }}
                var off = len - MemoryLayout<UInt32>.size*2
                guard let tx = BRTransactionParse(buf, off) else { return DispatchQueue.main.async { callback(transactions) }}
                tx.pointee.blockHeight =
                    UnsafeRawPointer(buf).advanced(by: off).assumingMemoryBound(to: UInt32.self).pointee.littleEndian
                off = off + MemoryLayout<UInt32>.size
                let timestamp = UnsafeRawPointer(buf).advanced(by: off).assumingMemoryBound(to: UInt32.self).pointee.littleEndian
                tx.pointee.timestamp = (timestamp == 0) ? timestamp : timestamp + UInt32(NSTimeIntervalSince1970)
                transactions.append(tx)
            }

            if sqlite3_errcode(self.db) != SQLITE_DONE { print(String(cString: sqlite3_errmsg(self.db))) }
            DispatchQueue.main.async {
                callback(transactions)
            }
        }
    }

    func loadBlocks(callback: @escaping ([BRBlockRef?])->Void) {
        queue.async {
            var blocks = [BRBlockRef?]()
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select ZHEIGHT, ZNONCE, ZTARGET, ZTOTALTRANSACTIONS, ZVERSION, ZTIMESTAMP, " +
                "ZBLOCKHASH, ZFLAGS, ZHASHES, ZMERKLEROOT, ZPREVBLOCK from ZBRMERKLEBLOCKENTITY", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }

            while sqlite3_step(sql) == SQLITE_ROW {
                guard let b = BRMerkleBlockNew() else { return DispatchQueue.main.async { callback(blocks) }}
                b.pointee.height = UInt32(bitPattern: sqlite3_column_int(sql, 0))
                b.pointee.nonce = UInt32(bitPattern: sqlite3_column_int(sql, 1))
                b.pointee.target = UInt32(bitPattern: sqlite3_column_int(sql, 2))
                b.pointee.totalTx = UInt32(bitPattern: sqlite3_column_int(sql, 3))
                b.pointee.version = UInt32(bitPattern: sqlite3_column_int(sql, 4))
                let result = UInt32(bitPattern: sqlite3_column_int(sql, 5)).addingReportingOverflow(UInt32(NSTimeIntervalSince1970))
                if result.1 {
                    print("skipped overflowed timestamp: \(sqlite3_column_int(sql, 5))")
                    continue
                } else {
                    b.pointee.timestamp = result.0
                }
                b.pointee.blockHash = sqlite3_column_blob(sql, 6).assumingMemoryBound(to: UInt256.self).pointee

                let flags: UnsafePointer<UInt8>? = SafeSqlite3ColumnBlob(statement: sql!, iCol: 7)
                let flagsLen = Int(sqlite3_column_bytes(sql, 7))
                let hashes: UnsafePointer<UInt256>? = SafeSqlite3ColumnBlob(statement: sql!, iCol: 8)
                let hashesCount = Int(sqlite3_column_bytes(sql, 8))/MemoryLayout<UInt256>.size
                BRMerkleBlockSetTxHashes(b, hashes, hashesCount, flags, flagsLen)
                b.pointee.merkleRoot = sqlite3_column_blob(sql, 9).assumingMemoryBound(to: UInt256.self).pointee
                b.pointee.prevBlock = sqlite3_column_blob(sql, 10).assumingMemoryBound(to: UInt256.self).pointee
                blocks.append(b)
            }

            if sqlite3_errcode(self.db) != SQLITE_DONE { print(String(cString: sqlite3_errmsg(self.db))) }
            DispatchQueue.main.async {
                callback(blocks)
            }
        }
    }

    func loadPeers(callback: @escaping ([BRPeer])->Void) {
        queue.async {
            var peers = [BRPeer]()
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select ZADDRESS, ZPORT, ZSERVICES, ZTIMESTAMP from ZBRPEERENTITY", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }

            while sqlite3_step(sql) == SQLITE_ROW {
                var p = BRPeer()
                p.address = UInt128(u32: (0, 0, UInt32(0xffff).bigEndian,
                                          UInt32(bitPattern: sqlite3_column_int(sql, 0)).bigEndian))
                p.port = UInt16(truncatingIfNeeded: sqlite3_column_int(sql, 1))
                p.services = UInt64(bitPattern: sqlite3_column_int64(sql, 2))

                let result = UInt64(bitPattern: sqlite3_column_int64(sql, 3)).addingReportingOverflow(UInt64(NSTimeIntervalSince1970))
                if result.1 {
                    print("skipped overflowed timestamp: \(sqlite3_column_int64(sql, 3))")
                    continue
                } else {
                    p.timestamp = result.0
                    peers.append(p)
                }
            }

            if sqlite3_errcode(self.db) != SQLITE_DONE { print(String(cString: sqlite3_errmsg(self.db))) }
            DispatchQueue.main.async {
                callback(peers)
            }
        }
    }
    
    // Wagerr specific
    func saveBetMapping(_ ent: BetMapping) {
        queue.async {
            var sql0: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select ZTXHASH from WGR_MAPPING where ZTXHASH = '\(ent.txHash)'", -1, &sql0, nil)
            defer { sqlite3_finalize(sql0) }

            if sqlite3_step(sql0) == SQLITE_ROW {   // mapping already exists... abandon
                return
            }
            
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select Z_MAX from Z_PRIMARYKEY where Z_ENT = \(self.mappingEnt)", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }

            guard sqlite3_step(sql) == SQLITE_ROW else {
                print(String(cString: sqlite3_errmsg(self.db)))
                sqlite3_exec(self.db, "rollback", nil, nil, nil)
                return
            }
            
            let pk = sqlite3_column_int(sql, 0)
            var sql2: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "insert or rollback into WGR_MAPPING " +
                "(Z_PK, ZVERSION, ZNAMESPACEID, ZMAPPINGID, ZSTRING, ZTIMESTAMP, ZHEIGHT, ZTXHASH) " +
                "values (\(pk + 1), \(ent.version), \(ent.namespaceID.rawValue), \(ent.mappingID) , ? , \(ent.timestamp), \(ent.blockheight), '\(ent.txHash)' )", -1, &sql2, nil)
            sqlite3_bind_text(sql2, 1, ent.description, -1, SQLITE_TRANSIENT)
            
            defer { sqlite3_finalize(sql2) }
            
            guard sqlite3_step(sql2) == SQLITE_DONE else {
                print("SQLITE error saveBetMapping: " + String(cString: sqlite3_errmsg(self.db)))
                return
            }

            sqlite3_exec(self.db, "update or rollback Z_PRIMARYKEY set Z_MAX = \(pk + 1) " +
                "where Z_ENT = \(self.mappingEnt) and Z_MAX = \(pk)", nil, nil, nil)

            guard sqlite3_errcode(self.db) == SQLITE_OK else {
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }

            sqlite3_exec(self.db, "commit", nil, nil, nil)
            self.setDBFileAttributes()
        }
    }
    
    func deleteBetMapping(_ txHash: String ) {
        queue.async {
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "delete from WGR_MAPPING where ZTXHASH = ?", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            sqlite3_bind_text(sql, 1, txHash, -1, SQLITE_TRANSIENT)

            guard sqlite3_step(sql) == SQLITE_DONE else {
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }
        }
    }
    
    func cleanChainBugs() {
       // fake team mappings for ID 187.
        deleteBetMapping("cc89779e8e57d49e5e6d3e16ad57e648b19d86fb8f4714bc7df5abd3f92daa1d")
        deleteBetMapping("d8e1e8389bbcffe1c79cf11e2206281377e54b99219ec6ccec296c2adb8ad65f")
        deleteBetMapping("929972a7b2fdf55f6da7488ccaf7312fd5d22c4bca003ca089293c93f1c32917")
        deleteBetMapping("e4e3a4f782569fa3bf0135297942c8a1c791ec869ca036bf530ab95633d17815")    // 2020/01/27
    }

    func saveBetEvent(_ ent: BetEventDatabaseModel) {
        queue.async {
            var sql0: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select ZEVENT_ID from WGR_EVENT where ZEVENT_ID = \(ent.eventID)", -1, &sql0, nil)
            defer { sqlite3_finalize(sql0) }

            if sqlite3_step(sql0) == SQLITE_ROW {   // event exists... update data
                var sql2: OpaquePointer? = nil
                sqlite3_prepare_v2(self.db, "update or rollback WGR_EVENT " +
                    " set ZEVENT_TIMESTAMP = \(ent.eventTimestamp), ZSPORT_ID = \(ent.sportID), ZTOURNAMENT_ID = \(ent.tournamentID), ZROUND_ID = \(ent.roundID), ZHOME_TEAM = \(ent.homeTeamID), ZAWAY_TEAM = \(ent.awayTeamID), ZLAST_UPDATED = \(ent.lastUpdated), ZTIMESTAMP = \(ent.timestamp), ZHEIGHT = \(ent.blockheight), ZTXHASH = '\(ent.txHash)' WHERE ZEVENT_ID = \(ent.eventID)", -1, &sql2, nil)
                defer { sqlite3_finalize(sql2) }
                
                guard sqlite3_step(sql2) == SQLITE_DONE else {
                    print("SQLITE error saveBetEvent (update): " + String(cString: sqlite3_errmsg(self.db)))
                    return
                }
            }
            else    {   // new event, insert
                var sql: OpaquePointer? = nil
                sqlite3_prepare_v2(self.db, "select Z_MAX from Z_PRIMARYKEY where Z_ENT = \(self.eventEnt)", -1, &sql, nil)
                defer { sqlite3_finalize(sql) }

                guard sqlite3_step(sql) == SQLITE_ROW else {
                    print(String(cString: sqlite3_errmsg(self.db)))
                    sqlite3_exec(self.db, "rollback", nil, nil, nil)
                    return
                }
                
                let pk = sqlite3_column_int(sql, 0)
                var sql2: OpaquePointer? = nil
                sqlite3_prepare_v2(self.db, "insert or rollback into WGR_EVENT " +
                    "(Z_PK, ZTYPE, ZVERSION, ZEVENT_ID, ZEVENT_TIMESTAMP, ZSPORT_ID, ZTOURNAMENT_ID, ZROUND_ID, ZHOME_TEAM, ZAWAY_TEAM, ZHOME_ODDS, ZAWAY_ODDS, ZDRAW_ODDS, ZENTRY_PRICE, ZSPREAD_POINTS, ZSPREAD_HOME_ODDS, ZSPREAD_AWAY_ODDS, ZTOTAL_POINTS, ZTOTAL_OVER_ODDS, ZTOTAL_UNDER_ODDS, ZLAST_UPDATED, ZTIMESTAMP, ZHEIGHT, ZTXHASH) " +
                    "values (\(pk + 1), \(ent.type.rawValue), \(ent.version), \(ent.eventID), \(ent.eventTimestamp) , \(ent.sportID), \(ent.tournamentID), \(ent.roundID) , \(ent.homeTeamID), \(ent.awayTeamID), \(ent.homeOdds) , \(ent.awayOdds), \(ent.drawOdds), \(ent.entryPrice) , \(ent.spreadPoints), \(ent.spreadHomeOdds), \(ent.spreadAwayOdds), \(ent.totalPoints) , \(ent.overOdds), \(ent.underOdds), \(ent.lastUpdated), \(ent.timestamp), \(ent.blockheight), '\(ent.txHash)' )", -1, &sql2, nil)
                defer { sqlite3_finalize(sql2) }
                
                guard sqlite3_step(sql2) == SQLITE_DONE else {
                    print("SQLITE error saveBetEvent (insert): " + String(cString: sqlite3_errmsg(self.db)))
                    return
                }

                sqlite3_exec(self.db, "update or rollback Z_PRIMARYKEY set Z_MAX = \(pk + 1) " +
                    "where Z_ENT = \(self.eventEnt) and Z_MAX = \(pk)", nil, nil, nil)

                guard sqlite3_errcode(self.db) == SQLITE_OK else {
                    print(String(cString: sqlite3_errmsg(self.db)))
                    return
                }
            }
            
            sqlite3_exec(self.db, "commit", nil, nil, nil)
            self.setDBFileAttributes()
        }
    }

    func updateOdds(_ ent: BetEventDatabaseModel) {
        queue.async {
            sqlite3_exec(self.db, "update or rollback WGR_EVENT set ZHOME_ODDS = \(ent.homeOdds), ZAWAY_ODDS = \(ent.awayOdds), ZDRAW_ODDS = \(ent.drawOdds) where ZEVENT_ID = \(ent.eventID)", nil, nil, nil)

            guard sqlite3_errcode(self.db) == SQLITE_OK else {
                print("SQLITE error updateOdds: " + String(cString: sqlite3_errmsg(self.db)))
                return
            }

            sqlite3_exec(self.db, "commit", nil, nil, nil)
            self.setDBFileAttributes()
        }
    }

    func updateSpreads(_ ent: BetEventDatabaseModel) {
        queue.async {
            sqlite3_exec(self.db, "update or rollback WGR_EVENT set ZSPREAD_POINTS = \(ent.spreadPoints), ZSPREAD_HOME_ODDS = \(ent.spreadHomeOdds), ZSPREAD_AWAY_ODDS = \(ent.spreadAwayOdds) where ZEVENT_ID = \(ent.eventID)", nil, nil, nil)

            guard sqlite3_errcode(self.db) == SQLITE_OK else {
                print("SQLITE error updateSpreads: " + String(cString: sqlite3_errmsg(self.db)))
                return
            }

            sqlite3_exec(self.db, "commit", nil, nil, nil)
            self.setDBFileAttributes()
        }
    }
    
    func updateTotals(_ ent: BetEventDatabaseModel) {
        queue.async {
            sqlite3_exec(self.db, "update or rollback WGR_EVENT set ZTOTAL_POINTS = \(ent.totalPoints), ZTOTAL_OVER_ODDS = \(ent.overOdds), ZTOTAL_UNDER_ODDS = \(ent.underOdds) where ZEVENT_ID = \(ent.eventID)", nil, nil, nil)
            
            guard sqlite3_errcode(self.db) == SQLITE_OK else {
                print("SQLITE error updateTotals: " + String(cString: sqlite3_errmsg(self.db)))
                return
            }

            sqlite3_exec(self.db, "commit", nil, nil, nil)
            self.setDBFileAttributes()
        }
    }
    
    func saveBetResult(_ ent: BetResult) {
        queue.async {
            var sql0: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select ZTXHASH from WGR_RESULT where ZTXHASH = '\(ent.txHash)'", -1, &sql0, nil)
            defer { sqlite3_finalize(sql0) }

            if sqlite3_step(sql0) == SQLITE_ROW {   // result exists... abandon
                return
            }
            
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select Z_MAX from Z_PRIMARYKEY where Z_ENT = \(self.resultEnt)", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }

            guard sqlite3_step(sql) == SQLITE_ROW else {
                print(String(cString: sqlite3_errmsg(self.db)))
                sqlite3_exec(self.db, "rollback", nil, nil, nil)
                return
            }

            let pk = sqlite3_column_int(sql, 0)
            var sql2: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "insert or rollback into WGR_RESULT " +
                "(Z_PK, ZTYPE, ZVERSION, ZEVENT_ID, ZRESULT_TYPE, ZHOME_TEAM_SCORE, ZAWAY_TEAM_SCORE, ZTIMESTAMP, ZHEIGHT, ZTXHASH) " +
                "values (\(pk + 1), \(ent.type.rawValue), \(ent.version), \(ent.eventID), \(ent.resultType.rawValue) , \(ent.homeScore), \(ent.awayScore), \(ent.timestamp), \(ent.blockheight), '\(ent.txHash)' )", -1, &sql2, nil)
            defer { sqlite3_finalize(sql2) }
            
            guard sqlite3_step(sql2) == SQLITE_DONE else {
                print("SQLITE error saveResult: " + String(cString: sqlite3_errmsg(self.db)))
                return
            }

            sqlite3_exec(self.db, "update or rollback Z_PRIMARYKEY set Z_MAX = \(pk + 1) " +
                "where Z_ENT = \(self.resultEnt) and Z_MAX = \(pk)", nil, nil, nil)

            guard sqlite3_errcode(self.db) == SQLITE_OK else {
                print(String(cString: sqlite3_errmsg(self.db)))
                return
            }

            sqlite3_exec(self.db, "commit", nil, nil, nil)
            self.setDBFileAttributes()
        }
    }
    
    func loadResultAtHeigh(blockHeight: Int, callback: @escaping (BetResult?)->Void  ) {
        var ret : BetResult?
        queue.async {
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, "select ZTYPE, ZEVENT_ID, ZRESULT_TYPE, ZHOME_TEAM_SCORE, ZAWAY_TEAM_SCORE, ZTIMESTAMP, ZHEIGHT, ZTXHASH from WGR_RESULT where ZHEIGHT = \(blockHeight)", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }
            
            guard sqlite3_step(sql) == SQLITE_ROW else {
                print(String(cString: sqlite3_errmsg(self.db)))
                sqlite3_exec(self.db, "rollback", nil, nil, nil)
                return
            }

            let resultType = UInt32(sqlite3_column_int(sql, 2))
            ret = BetResult.init(blockheight: UInt64(sqlite3_column_int(sql, 6))
                , timestamp: TimeInterval(UInt64(bitPattern: sqlite3_column_int64(sql, 5)))
                , txHash: String(cString: sqlite3_column_text(sql, 7))
                , version: 1
                , type: .RESULT_PEERLESS
                , eventID: UInt64(sqlite3_column_int(sql, 1))
                , resultType: BetResultType( rawValue : (resultType != 0) ? Int32(bitPattern: resultType) : -1)!
                , homeScore: UInt32(sqlite3_column_int(sql, 3))
                , awayScore: UInt32(sqlite3_column_int(sql, 4)))
            
            DispatchQueue.main.async {
                callback(ret)
            }
        }
    }
        
    func loadMappingsByNamespaceId( namespaceID : Int32 ,  mappingID : Int32 )  {
        queue.async {
            var mappings = [BetMapping?]()
            var sql: OpaquePointer? = nil
            //sqlite3_prepare_v2(self.db, "select ZTXHASH from WGR_MAPPING where ZNAMESPACEID = \(namespaceID) and ZMAPPINGID = \(mappingID)", -1, &sql, nil)
            sqlite3_prepare_v2(self.db, "select ZTXHASH, ZNAMESPACEID from WGR_MAPPING where ZMAPPINGID = \(mappingID)", -1, &sql, nil)
            defer { sqlite3_finalize(sql) }

            while sqlite3_step(sql) == SQLITE_ROW {
                let txHash = String(cString: sqlite3_column_text(sql, 0))
                let namespace = UInt32(bitPattern: sqlite3_column_int(sql, 1))
            }

            if sqlite3_errcode(self.db) != SQLITE_DONE { print(String(cString: sqlite3_errmsg(self.db))) }
        }
    }

    func loadEvents(_ eventID : UInt64,_ eventTimestamp : TimeInterval, callback: @escaping ([BetEventViewModel?])->Void) {

            var events = [BetEventViewModel?]()
            var sql: OpaquePointer? = nil
            sqlite3_prepare_v2(self.db, self.getEventsQuery( eventID, eventTimestamp ), -1, &sql, nil)
            defer { sqlite3_finalize(sql) }

            while sqlite3_step(sql) == SQLITE_ROW {
                let txSport = sqlite3_column_text(sql, 23)
                let txTournament = sqlite3_column_text(sql, 24)
                let txRound = sqlite3_column_text(sql, 25)
                let txHomeTeam = sqlite3_column_text(sql, 26)
                let txAwayTeam = sqlite3_column_text(sql, 27)
                let resultType = UInt32(sqlite3_column_int(sql, 28))
                let event = BetEventViewModel(blockheight: UInt64(bitPattern: sqlite3_column_int64(sql, 20)),
                    timestamp: TimeInterval(UInt64(bitPattern: sqlite3_column_int64(sql, 21))),
                    lastUpdated: TimeInterval(UInt64(bitPattern: sqlite3_column_int64(sql, 22))),
                    txHash: String(cString: sqlite3_column_text(sql, 0)),
                    version: UInt32(bitPattern: sqlite3_column_int(sql, 2)),
                    type: BetTransactionType( rawValue: Int32(bitPattern: UInt32(sqlite3_column_int(sql, 1))) )!,
                    eventID: UInt64(bitPattern: sqlite3_column_int64(sql, 3)),
                    eventTimestamp: TimeInterval(UInt64(bitPattern: sqlite3_column_int64(sql, 4))),
                    sportID: UInt32(bitPattern: sqlite3_column_int(sql, 5)),
                    tournamentID: UInt32(bitPattern: sqlite3_column_int(sql, 6)),
                    roundID: UInt32(bitPattern: sqlite3_column_int(sql, 7)),
                    homeTeamID: UInt32(bitPattern: sqlite3_column_int(sql, 8)),
                    awayTeamID: UInt32(bitPattern: sqlite3_column_int(sql, 9)),
                    homeOdds: UInt32(bitPattern: sqlite3_column_int(sql, 10)),
                    awayOdds: UInt32(bitPattern: sqlite3_column_int(sql, 11)),
                    drawOdds: UInt32(bitPattern: sqlite3_column_int(sql, 12)),
                    entryPrice: UInt32(bitPattern: sqlite3_column_int(sql, 13)),
                    spreadPoints: UInt32(bitPattern: sqlite3_column_int(sql, 14)),
                    spreadHomeOdds: UInt32(bitPattern: sqlite3_column_int(sql, 15)),
                    spreadAwayOdds: UInt32(bitPattern: sqlite3_column_int(sql, 16)),
                    totalPoints: UInt32(bitPattern: sqlite3_column_int(sql, 17)),
                    overOdds: UInt32(bitPattern: sqlite3_column_int(sql, 18)),
                    underOdds: UInt32(bitPattern: sqlite3_column_int(sql, 19)),
                    txSport: (txSport != nil) ? self.utf8Decode2(String(cString: txSport!)) : "",
                    txTournament: (txTournament != nil) ? self.utf8Decode2(String(cString: txTournament!)) : "",
                    txRound: (txRound != nil) ? self.utf8Decode2(String(cString: txRound!)) : "",
                    txHomeTeam: (txHomeTeam != nil) ? self.utf8Decode2(String(cString: txHomeTeam!)) : "",
                    txAwayTeam: (txAwayTeam != nil) ? self.utf8Decode2(String(cString: txAwayTeam!)) : "",
                    resultType: BetResultType( rawValue : (resultType != 0) ? Int32(bitPattern: resultType) : -1)!,
                    homeScore: UInt32(bitPattern: sqlite3_column_int(sql, 29)),
                    awayScore: UInt32(bitPattern: sqlite3_column_int(sql, 30)) );
                
                if eventID > 0 || !event.zeroedOdds()  {
                   // if event.homeTeamID == 1449     {
                    //    loadMappingsByNamespaceId(namespaceID: 3,mappingID: 1449)
                //   }
                    events.append(event)
                }
            

            if sqlite3_errcode(self.db) != SQLITE_DONE { print("SQLITE error loadEvents: " + String(cString: sqlite3_errmsg(self.db))) }
            DispatchQueue.main.async {
                callback(events)
            }
        }
    }

    // undo double utf8 encoding
    func utf8Decode2(_ str : String ) -> String {
        var bytesIterator = str.utf8.makeIterator()
        var scalars: [Unicode.Scalar] = []
        var utf8Decoder = UTF8()
        Decode: while true {
            switch utf8Decoder.decode(&bytesIterator) {
            case .scalarValue(let v): scalars.append(v)
            case .emptyInput: break Decode
            case .error:
                print("Decoding error")
                break Decode
            }
        }
        let arrBytes = scalars.map { (UInt8)((UInt32)($0)&0xff) }
        var bytesIterator2 = arrBytes.makeIterator()
        scalars.removeAll()
        Decode2: while true {
            switch utf8Decoder.decode(&bytesIterator2) {
            case .scalarValue(let v): scalars.append(v)
            case .emptyInput: break Decode2
            case .error:
                print("Decoding error 2")
                break Decode2
            }
        }
        var ret = ""
        ret.unicodeScalars.append(contentsOf: scalars)
        return ret
    }
    
    func getEventsQuery(_ eventID : UInt64,_ eventTimestamp : TimeInterval ) -> String {
        
        var QUERY = "SELECT DISTINCT a.ZTXHASH, a.ZTYPE, a.ZVERSION, a.ZEVENT_ID, a.ZEVENT_TIMESTAMP, a.ZSPORT_ID, a.ZTOURNAMENT_ID, a.ZROUND_ID, a.ZHOME_TEAM, a.ZAWAY_TEAM, a.ZHOME_ODDS, a.ZAWAY_ODDS, a.ZDRAW_ODDS, a.ZENTRY_PRICE, a.ZSPREAD_POINTS, a.ZSPREAD_HOME_ODDS, a.ZSPREAD_AWAY_ODDS, a.ZTOTAL_POINTS, a.ZTOTAL_OVER_ODDS, a.ZTOTAL_UNDER_ODDS, a.ZHEIGHT, a.ZTIMESTAMP, a.ZLAST_UPDATED"
                // event mappings
                + ", s.ZSTRING, t.ZSTRING, r.ZSTRING, b.ZSTRING, c.ZSTRING "
                // event results
                + ", o.ZRESULT_TYPE, o.ZHOME_TEAM_SCORE, o.ZAWAY_TEAM_SCORE "
+ ", a.Z_PK "
                + " FROM WGR_EVENT a "
                // sport (s), tournament (t), round (r)
                + " LEFT OUTER JOIN WGR_MAPPING s ON a.ZSPORT_ID = s.ZMAPPINGID "
            + " AND s.ZNAMESPACEID = \(MappingNamespaceType.SPORT.rawValue) "
                + " LEFT OUTER JOIN WGR_MAPPING t ON a.ZTOURNAMENT_ID = t.ZMAPPINGID "
                + " AND t.ZNAMESPACEID = \(MappingNamespaceType.TOURNAMENT.rawValue) "
                + " LEFT OUTER JOIN WGR_MAPPING r ON a.ZROUND_ID = r.ZMAPPINGID "
                + " AND r.ZNAMESPACEID = \(MappingNamespaceType.ROUNDS.rawValue) "
                // home team (b), away team (c)
                + " LEFT OUTER JOIN WGR_MAPPING b ON a.ZHOME_TEAM = b.ZMAPPINGID "
                + " AND b.ZNAMESPACEID = \(MappingNamespaceType.TEAM_NAME.rawValue) "
                + " LEFT OUTER JOIN WGR_MAPPING c ON a.ZAWAY_TEAM = c.ZMAPPINGID "
                + " AND c.ZNAMESPACEID = \(MappingNamespaceType.TEAM_NAME.rawValue) "
                // result table (o)
                + " LEFT OUTER JOIN WGR_RESULT o ON a.ZEVENT_ID = o.ZEVENT_ID ";
                
            if ( eventID>0 || eventTimestamp>0 )  {
                QUERY += " WHERE 1=1 ";
            }
    
            if (eventID>0)  {
                QUERY += " AND a.ZEVENT_ID = \(eventID) "
            }

            if (eventTimestamp>0)   {
                QUERY += " AND a.ZEVENT_TIMESTAMP > \(eventTimestamp) "
            }
            QUERY += " ORDER BY a.ZEVENT_TIMESTAMP ";

        return QUERY;
    }
}
