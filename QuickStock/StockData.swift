//
//  StockData.swift
//  QuickStock
//
//  Created by Radim Veselý on 10.03.2025.
//

import Foundation
import SQLite3
import AppKit

class StockDataManager {
    private var db: OpaquePointer?

    init() {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("QuickStock/StockData.sqlite")

        #if DEBUG
        print("📂 [DB] File path: \(fileURL.path)")
        #endif

        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        } catch {
            #if DEBUG
            print("❌ [DB Init] Failed to create directory: \(error.localizedDescription)")
            #endif
            showAlert("[DB Init] Failed to create directory", message: error.localizedDescription)
        }

        if sqlite3_open_v2(fileURL.path, &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil) != SQLITE_OK {
            #if DEBUG
            print("❌ [DB Init] Failed to open database")
            #endif
            showAlert("[DB Init] Failed to open database")
        } else {
            createTable()
        }
    }

    private func createTable() {
        let createTableString = """
        CREATE TABLE IF NOT EXISTS StockMetrics (
            ticker TEXT PRIMARY KEY,
            peRatioTTM REAL,
            roeTTM REAL,
            roicTTM REAL,
            priceToSalesRatioTTM REAL,
            returnOnTangibleAssetsTTM REAL,
            netProfitMarginTTM REAL,
            debtToEquityTTM REAL,
            currentRatioTTM REAL,
            freeCashFlowPerShareTTM REAL,
            netIncomePerShareTTM REAL,
            marketCapTTM REAL,
            dividendYieldTTM REAL,
            bookValuePerShareTTM REAL,
            ebitMarginTTM REAL,
            isPremiumRestricted INTEGER DEFAULT 0
        );
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                #if DEBUG
                print("❌ [DB] Failed to create table")
                #endif
                showAlert("[DB] Failed to create table")
            }
        } else {
            #if DEBUG
            print("❌ [DB] Table creation prepare failed")
            #endif
            showAlert("[DB] Table creation prepare failed")
        }
        sqlite3_finalize(statement)
    }

    func saveData(for ticker: String, data: StockMetrics) {
        let cleanTicker = ticker.trimmingCharacters(in: .whitespacesAndNewlines)
        let insertString = """
        INSERT OR REPLACE INTO StockMetrics (ticker, peRatioTTM, roeTTM, roicTTM, priceToSalesRatioTTM, returnOnTangibleAssetsTTM,
        netProfitMarginTTM, debtToEquityTTM, currentRatioTTM, freeCashFlowPerShareTTM,
        netIncomePerShareTTM, marketCapTTM, dividendYieldTTM, bookValuePerShareTTM, ebitMarginTTM, isPremiumRestricted)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertString, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (cleanTicker as NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 2, data.peRatioTTM ?? 0)
            sqlite3_bind_double(statement, 3, data.roeTTM ?? 0)
            sqlite3_bind_double(statement, 4, data.roicTTM ?? 0)
            sqlite3_bind_double(statement, 5, data.priceToSalesRatioTTM ?? 0)
            sqlite3_bind_double(statement, 6, data.returnOnTangibleAssetsTTM ?? 0)
            sqlite3_bind_double(statement, 7, data.netProfitMarginTTM ?? 0)
            sqlite3_bind_double(statement, 8, data.debtToEquityTTM ?? 0)
            sqlite3_bind_double(statement, 9, data.currentRatioTTM ?? 0)
            sqlite3_bind_double(statement, 10, data.freeCashFlowPerShareTTM ?? 0)
            sqlite3_bind_double(statement, 11, data.netIncomePerShareTTM ?? 0)
            sqlite3_bind_double(statement, 12, data.marketCapTTM ?? 0)
            sqlite3_bind_double(statement, 13, data.dividendYieldTTM ?? 0)
            sqlite3_bind_double(statement, 14, data.bookValuePerShareTTM ?? 0)
            sqlite3_bind_double(statement, 15, data.ebitMarginTTM ?? 0)
            sqlite3_bind_int(statement, 16, (data.isPremiumRestricted ?? false) ? 1 : 0)

            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                #if DEBUG
                print("❌ [DB] Failed to save data: \(errorMessage)")
                #endif
                showAlert("[DB] Failed to save data", message: errorMessage)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            #if DEBUG
            print("❌ [DB] Prepare insert failed: \(errorMessage)")
            #endif
            showAlert("[DB] Prepare insert failed", message: errorMessage)
        }
        sqlite3_finalize(statement)
    }

    func loadData(for ticker: String) -> StockMetrics? {
        let query = "SELECT * FROM StockMetrics WHERE ticker = ?;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (ticker as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_ROW {
                func getOptionalDouble(_ index: Int32) -> Double? {
                    return sqlite3_column_type(statement, index) != SQLITE_NULL ? sqlite3_column_double(statement, index) : nil
                }

                let peRatioTTM = getOptionalDouble(1)
                let roeTTM = getOptionalDouble(2)
                let roicTTM = getOptionalDouble(3)
                let priceToSalesRatioTTM = getOptionalDouble(4)
                let returnOnTangibleAssetsTTM = getOptionalDouble(5)
                let netProfitMarginTTM = getOptionalDouble(6)
                let debtToEquityTTM = getOptionalDouble(7)
                let currentRatioTTM = getOptionalDouble(8)
                let freeCashFlowPerShareTTM = getOptionalDouble(9)
                let netIncomePerShareTTM = getOptionalDouble(10)
                let marketCapTTM = getOptionalDouble(11)
                let dividendYieldTTM = getOptionalDouble(12)
                let bookValuePerShareTTM = getOptionalDouble(13)
                let ebitMarginTTM = getOptionalDouble(14)
                let isPremiumRestricted = sqlite3_column_int(statement, 15) == 1

                let metrics = StockMetrics(
                    peRatioTTM: peRatioTTM,
                    roeTTM: roeTTM,
                    roicTTM: roicTTM,
                    priceToSalesRatioTTM: priceToSalesRatioTTM,
                    returnOnTangibleAssetsTTM: returnOnTangibleAssetsTTM,
                    netProfitMarginTTM: netProfitMarginTTM,
                    debtToEquityTTM: debtToEquityTTM,
                    currentRatioTTM: currentRatioTTM,
                    freeCashFlowPerShareTTM: freeCashFlowPerShareTTM,
                    netIncomePerShareTTM: netIncomePerShareTTM,
                    marketCapTTM: marketCapTTM,
                    dividendYieldTTM: dividendYieldTTM,
                    bookValuePerShareTTM: bookValuePerShareTTM,
                    ebitMarginTTM: ebitMarginTTM,
                    isPremiumRestricted: isPremiumRestricted
                )
                sqlite3_finalize(statement)
                return metrics
            }
        } else {
            #if DEBUG
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ [DB] Prepare select failed: \(errorMessage)")
            #endif
        }
        sqlite3_finalize(statement)
        return nil
    }

    func deleteData(for ticker: String) {
        let deleteString = "DELETE FROM StockMetrics WHERE ticker = ?;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteString, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (ticker as NSString).utf8String, -1, nil)
            _ = sqlite3_step(statement)
        } else {
            #if DEBUG
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ [DB] Prepare delete failed: \(errorMessage)")
            #endif
        }
        sqlite3_finalize(statement)
    }

    private func showAlert(_ title: String, message: String = "") {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            if !message.isEmpty { alert.informativeText = message }
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
}
