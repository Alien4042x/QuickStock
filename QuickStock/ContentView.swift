//
//  ContentView.swift
//  QuickStock
//
//  Created by Radim Veselý on 08.03.2025.
//

import SwiftUI
import AppKit

extension Color {
    static let customDarkGray = Color(red: 0.137, green: 0.145, blue: 0.149) // #232526
    static let customMidGray  = Color(red: 0.255, green: 0.263, blue: 0.271) // #414345
    static let customGold = Color(red: 1.0, green: 0.84, blue: 0.0) // #FFD700
}

struct StockMetrics: Codable {
    var peRatioTTM: Double?
    var roeTTM: Double?
    var roicTTM: Double?
    var priceToSalesRatioTTM: Double?
    var returnOnTangibleAssetsTTM: Double?
    var netProfitMarginTTM: Double?
    var debtToEquityTTM: Double?
    var currentRatioTTM: Double?
    var freeCashFlowPerShareTTM: Double?
    var netIncomePerShareTTM: Double?
    var marketCapTTM: Double?
    var dividendYieldTTM: Double?
    var bookValuePerShareTTM: Double?
    var ebitMarginTTM: Double?
    var isPremiumRestricted: Bool?
}

struct CustomTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = text

        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.black.withAlphaComponent(0.6),
            .font: NSFont.systemFont(ofSize: 15)
        ]
        textField.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: placeholderAttributes
        )

        textField.backgroundColor = .clear
        textField.isBordered = false
        textField.textColor = .white
        textField.focusRingType = .none
        textField.drawsBackground = false
        textField.font = NSFont.systemFont(ofSize: 16)

        textField.delegate = context.coordinator
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        DispatchQueue.main.async {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CustomTextField

        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
    }
}

struct ContentView: View {
    @State private var score: Int = 0
    @State private var ticker: String = ""
    @State private var stockData: [(String, String, Color)] = []
    @State private var isLoading = false
    @State private var showApiKeyWindow: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    private let stockService = StockService()

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.customDarkGray, Color.customMidGray]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            .onReceive(NotificationCenter.default.publisher(for: .showApiKeySettings)) { _ in
                showApiKeyWindow = true
            }

            VStack(spacing: 20) {
                HStack {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 40)

                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .padding(.leading, 10)

                            CustomTextField(text: $ticker, placeholder: "Enter Ticker")
                                .frame(height: 40)
                        }
                        .padding(.horizontal, 10)
                    }
                    .frame(width: 250)

                    Button(action: findStock) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Find")
                                .font(.headline)
                                .foregroundColor(Color.black)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 30)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.070, green: 0.6, blue: 0.557),
                                            Color(red: 0.22, green: 0.937, blue: 0.490)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
                .padding()

                if showError, let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        Text(error)
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    .padding(10)
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(8)
                    .shadow(radius: 5)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(0..<stockData.count / 2, id: \ .self) { index in
                            metricRow(data: stockData[index])
                        }
                    }
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .frame(height: 200)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(stockData.count / 2..<stockData.count, id: \ .self) { index in
                            metricRow(data: stockData[index])
                        }
                    }
                }
                .padding()
            }
            .padding()
        }
        .onAppear {
            if ApiKeyStorage.loadApiKey() == nil {
                showApiKeyWindow = true
            }
        }
        .sheet(isPresented: $showApiKeyWindow) {
            ApiKeySettingsView(showApiKeyWindow: $showApiKeyWindow)
        }
    }

    private func findStock() {
        guard !ticker.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        showError = false

        stockService.fetchStockData(for: ticker) { metrics, errorType in
            isLoading = false

            if let metrics = metrics {
                updateStockData(from: metrics)
                errorMessage = nil
                showError = false
            } else {
                switch errorType {
                case .premiumOnly:
                    errorMessage = "This ticker requires a premium API plan."
                case .notFound:
                    errorMessage = "Ticker '\(ticker)' not found."
                case .missingApiKey:
                    errorMessage = "API key is missing."
                default:
                    errorMessage = "Unknown error occurred."
                }
                showError = true
            }
        }
    }

    // Determines color based on P/E ratio
    private func colorForPE(_ peRatio: Double?) -> Color {
        guard let pe = peRatio else { return .gray }
        
        let red = Color(red: 0.93, green: 0.35, blue: 0.25)    // #ED5940
        let yellow = Color.yellow
        let green = Color.green

        if pe < 0 {
            return red
        } else if pe <= 15 {
            return green
        } else if pe <= 30 {
            return yellow
        } else {
            return red
        }
    }
    
    private func colorForMetric(value: Double?, metric: String, isPremium: Bool = false) -> Color {
        guard !isPremium, let val = value else { return isPremium ? .yellow : .gray }

        switch metric {
        case "ROE", "ROIC":
            if val > 1.0 { return .customGold }         // above 100 %
            if val > 0.3 { return .green }              // above 30 %
            return .red

        case "Profit Margin":
            if val > 0.4 { return .customGold }         // above 40 %
            if val > 0.1 { return .green }              // above 10 %
            return .red

        default:
            return val > 0 ? .green : .red
        }
    }

    // Determines color for positive values
    private func colorForPositiveValue(_ value: Double?) -> Color {
        guard let value = value else { return .gray }
        return value > 0 ? .green : .red
    }

    // Formats number for better readability
    private func formatNumber(_ value: Double?) -> String {
        guard let value = value else { return "-" }
        return String(format: "%.2f", value)
    }

    // Formats percentage values
    private func formatPercentage(_ value: Double?) -> String {
        guard let value = value else { return "-" }
        return String(format: "%.2f%%", value * 100)
    }

    // Formats market capitalization into M, B, or T
    private func formatMarketCap(_ value: Double?) -> String {
        guard let value = value else { return "-" }
        if value >= 1_000_000_000_000 {
            return String(format: "%.2fT", value / 1_000_000_000_000) // Trillion
        } else if value >= 1_000_000_000 {
            return String(format: "%.2fB", value / 1_000_000_000) // Billion
        } else {
            return String(format: "%.2fM", value / 1_000_000) // Million
        }
    }

    func updateStockData(from metrics: StockMetrics) {
        stockData = [
            ("Market Cap", formatMarketCap(metrics.marketCapTTM), .green),
            ("P/E Ratio", formatNumber(metrics.peRatioTTM), colorForPE(metrics.peRatioTTM)),
            ("Price to Sales", formatNumber(metrics.priceToSalesRatioTTM), colorForPositiveValue(metrics.priceToSalesRatioTTM)),
            ("ROE", formatPercentage(metrics.roeTTM), colorForMetric(value: metrics.roeTTM, metric: "ROE")),
            ("ROIC", formatPercentage(metrics.roicTTM), colorForMetric(value: metrics.roicTTM, metric: "ROIC")),
            ("ROA", formatPercentage(metrics.returnOnTangibleAssetsTTM), colorForPositiveValue(metrics.returnOnTangibleAssetsTTM)),
            ("Book Value", "$" + formatNumber(metrics.bookValuePerShareTTM), colorForPositiveValue(metrics.bookValuePerShareTTM)),

            ("Profit Margin", metrics.isPremiumRestricted == true ? "🔒 Premium" : formatPercentage(metrics.netProfitMarginTTM),
             colorForMetric(value: metrics.netProfitMarginTTM, metric: "Profit Margin", isPremium: metrics.isPremiumRestricted == true)),
            ("EBIT Margin",
             metrics.isPremiumRestricted == true ? "🔒 Premium" : formatPercentage(metrics.ebitMarginTTM),
             colorForMetric(value: metrics.ebitMarginTTM, metric: "Profit Margin", isPremium: metrics.isPremiumRestricted == true)),
            ("Debt/Equity", formatNumber(metrics.debtToEquityTTM), metrics.debtToEquityTTM ?? 0 < 1 ? .green : .red),
            ("Current Ratio", formatNumber(metrics.currentRatioTTM), metrics.currentRatioTTM ?? 0 > 1 ? .green : .red),
            ("Free Cash Flow", "$" + formatNumber(metrics.freeCashFlowPerShareTTM), colorForPositiveValue(metrics.freeCashFlowPerShareTTM)),
            ("EPS", formatNumber(metrics.netIncomePerShareTTM), colorForPositiveValue(metrics.netIncomePerShareTTM)),
        ]

        stockData.append(
            ("Dividend Yield", metrics.dividendYieldTTM != nil ? String(format: "%.2f%%", metrics.dividendYieldTTM! * 100) : "-", metrics.dividendYieldTTM ?? 0 > 0 ? .green : .clear)
        )
    }

    private func metricRow(data: (String, String, Color)) -> some View {
        HStack {
            Text(data.0)
                .font(.headline)
                .frame(width: 150, alignment: .leading)
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)

            Spacer()

            Text(data.1)
                .font(.body)
                .bold()
                .foregroundColor(data.2)
                .padding(.horizontal, 10)
                .background(data.2.opacity(0.2))
                .cornerRadius(5)
                .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
        }
    }
}

extension Notification.Name {
    static let showApiKeySettings = Notification.Name("ShowApiKeySettings")
}


#Preview {
    ContentView()
}
