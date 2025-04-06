//
//  StockService.swift
//  QuickStock
//
//  Created by Radim Veselý on 10.03.2025.
//

import Foundation
import SwiftUI

class StockService {
    enum StockErrorType {
        case none
        case notFound
        case premiumOnly
        case missingApiKey
    }

    private let dataManager = StockDataManager()
    private let lastUpdateKey = "lastUpdateKey"

    func fetchStockData(for ticker: String, completion: @escaping (StockMetrics?, StockErrorType) -> Void) {
        if shouldUpdateData(for: ticker) {
            guard let apiKey = ApiKeyStorage.loadApiKey() else {
                completion(nil, .missingApiKey)
                return
            }

            let urlString = "https://financialmodelingprep.com/api/v3/key-metrics-ttm/\(ticker)?apikey=\(apiKey)"

            guard let url = URL(string: urlString) else {
                completion(nil, .notFound)
                return
            }

            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    if error != nil {
                        completion(nil, .notFound)
                        return
                    }

                    guard let data = data else {
                        completion(nil, .notFound)
                        return
                    }

                    if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                       let message = errorResponse["Error Message"] ?? errorResponse["message"] ?? errorResponse["note"],
                       message.contains("Premium Query") {
                        #if DEBUG
                        print("Premium-only ticker: \(ticker)")
                        #endif
                        completion(nil, .premiumOnly)
                        return
                    }

                    do {
                        let decodedData = try JSONDecoder().decode([StockMetrics].self, from: data)
                        if var metrics = decodedData.first,
                           [metrics.peRatioTTM, metrics.roeTTM, metrics.marketCapTTM].contains(where: { $0 != nil && $0! > 0 }) {

                            self.fetchAdditionalMetrics(for: ticker) { additionalMetrics, addError in
                                metrics.netProfitMarginTTM = additionalMetrics?.netProfitMarginTTM ?? metrics.netProfitMarginTTM
                                metrics.ebitMarginTTM = additionalMetrics?.ebitMarginTTM ?? metrics.ebitMarginTTM
                                metrics.isPremiumRestricted = additionalMetrics?.isPremiumRestricted ?? false

                                self.dataManager.saveData(for: ticker, data: metrics)
                                self.updateLastFetchTime(for: ticker)
                                completion(metrics, .none)
                            }

                        } else {
                            completion(nil, .notFound)
                        }
                    } catch {
                        completion(nil, .notFound)
                    }
                }
            }.resume()

        } else {
            if let cachedData = dataManager.loadData(for: ticker) {
                completion(cachedData, .none)
            } else {
                completion(nil, .notFound)
            }
        }
    }

    // Helper to fetch additional metrics only, without detailed error type
    private func fetchAdditionalMetrics(for ticker: String, completion: @escaping (StockMetrics?, StockErrorType) -> Void) {
        guard let apiKey = ApiKeyStorage.loadApiKey() else {
            completion(nil, .missingApiKey)
            return
        }

        let urlString = "https://financialmodelingprep.com/stable/ratios-ttm?symbol=\(ticker)&apikey=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(nil, .notFound)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let string = String(data: data, encoding: .utf8),
                   string.contains("Premium Query") {
                    // Premium endpoint, API response is not JSON
                    let premiumStub = StockMetrics(isPremiumRestricted: true)
                    completion(premiumStub, .premiumOnly)
                    return
                }

                guard let data = data else {
                    completion(nil, .notFound)
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode([StockMetrics].self, from: data)
                    completion(decoded.first, .none)
                } catch {
                    #if DEBUG
                    print("❌ Additional metrics decode failed: \(error.localizedDescription)")
                    #endif
                    completion(nil, .notFound)
                }
            }
        }.resume()
    }

    private func shouldUpdateData(for ticker: String) -> Bool {
        let lastUpdate = UserDefaults.standard.object(forKey: "\(lastUpdateKey)_\(ticker)") as? Date ?? Date.distantPast
        let now = Date()

        if dataManager.loadData(for: ticker) == nil {
            return true
        }

        return now.timeIntervalSince(lastUpdate) > 24 * 60 * 60
    }


    private func updateLastFetchTime(for ticker: String) {
        UserDefaults.standard.set(Date(), forKey: "\(lastUpdateKey)_\(ticker)")
    }

    private func encrypt(_ apiKey: String) -> String {
        return apiKey // Placeholder
    }

    private func decrypt(_ encryptedApiKey: String) -> String? {
        return encryptedApiKey // Placeholder
    }
}
