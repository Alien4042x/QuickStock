//
//  ApiSettingsView.swift
//  QuickStock
//
//  Created by Radim Veselý on 09.03.2025.
//

import SwiftUI
import AppKit
import Foundation

// Structure for decoding JSON response
struct StockProfile: Codable {
    let symbol: String
    let price: Double
    let companyName: String
    let currency: String
    let industry: String
    let website: String
}

struct ApiKeyTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = text
        
        // Placeholder as NSAttributedString
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.black.withAlphaComponent(0.6),
            .font: NSFont.systemFont(ofSize: 15)
        ]
        textField.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: placeholderAttributes
        )

        // Styling
        textField.backgroundColor = .clear
        textField.isBordered = false
        textField.textColor = .white
        textField.focusRingType = .none
        textField.drawsBackground = false
        textField.font = NSFont.systemFont(ofSize: 16)
        
        // Single line limit
        textField.lineBreakMode = .byTruncatingTail
        textField.usesSingleLineMode = true // Only one line
        
        // Ensures SwiftUI doesn't expand the field
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

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
        var parent: ApiKeyTextField

        init(_ parent: ApiKeyTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
    }
}


struct ApiKeySettingsView: View {
    @Binding var showApiKeyWindow: Bool
    @State private var apiKey: String = ApiKeyStorage.loadApiKey() ?? ""
    @State private var statusMessage: String = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.customMidGray.edgesIgnoringSafeArea(.all)
                .ignoresSafeArea()
            
            VStack {
                Spacer() // Center alignment vertically
                
                VStack(alignment: .center, spacing: 20) {
                    HStack {
                        Text("API Key:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.2)) // Semi-transparent background
                                .frame(height: 40)
                            
                            ApiKeyTextField(text: $apiKey, placeholder: "Enter API Key")
                                .frame(height: 40)
                                .padding(.horizontal, 10)
                                .multilineTextAlignment(.leading)
                                .font(.system(size: 20))
                                .lineLimit(3)
                        }
                    }
                    
                    // Status message (highlighting error message)
                    if !statusMessage.isEmpty {
                        HStack {
                            Text(statusMessage)
                                .foregroundColor(statusMessage.contains("✅") ? .green : Color.white.opacity(1.0))
                                .fontWeight(.heavy)
                        }
                        .padding(.top, -10) // Light alignment up
                    }
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.top, 10)
                    }
                    
                    // Center button
                    Button(action: {
                        saveApiKey()
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(Color.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 30)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .frame(width: 400, height: 200)
                .cornerRadius(12)
                
                Spacer() // Center alignment vertically
            }
        }
        .frame(width: 420, height: 220) // Slightly larger window for a better view
    }
    
    private func saveApiKey() {
        guard !apiKey.isEmpty else {
            statusMessage = "❌ API Key cannot be empty"
            return
        }
        
        verifyApiKey(apiKey) { isValid in
            if isValid {
                ApiKeyStorage.saveApiKey(apiKey)
                statusMessage = "✅ API Key saved successfully"
                showApiKeyWindow = false
            } else {
                ApiKeyStorage.deleteApiKey()
                apiKey = ""
                statusMessage = "❌ Invalid API Key"
            }
        }
    }
    
    private func verifyApiKey(_ apiKey: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://financialmodelingprep.com/api/v3/profile/AAPL?apikey=\(apiKey)") else {
            statusMessage = "❌ Invalid URL"
            completion(false)
            return
        }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                defer { isLoading = false }
                
                if let error = error {
                    statusMessage = "❌ Network error: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                
                // Check HTTP status code
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        break
                    case 400:
                        statusMessage = "❌ Bad Request – Invalid API format"
                        completion(false)
                    case 401:
                        statusMessage = "❌ Unauthorized – Invalid API key"
                        completion(false)
                    case 403:
                        statusMessage = "❌ Forbidden – API key might be blocked"
                        completion(false)
                    case 404:
                        statusMessage = "❌ Not Found – Incorrect URL or ticker"
                        completion(false)
                    case 500...599:
                        statusMessage = "❌ Server error – Try again later"
                        completion(false)
                    default:
                        statusMessage = "❌ HTTP Error: \(httpResponse.statusCode)"
                        completion(false)
                    }
                }
                
                guard let data = data else {
                    statusMessage = "❌ No data received"
                    completion(false)
                    return
                }
                
                // JSON Parsing
                do {
                    let decodedData = try JSONDecoder().decode([StockProfile].self, from: data)
                    if let firstProfile = decodedData.first {
                        statusMessage = "✅ API Key is valid for \(firstProfile.companyName)"
                        completion(true)
                    } else {
                        statusMessage = "❌ Invalid JSON structure"
                        completion(false)
                    }
                } catch {
                    statusMessage = "❌ JSON decoding error: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }.resume()
    }
}
