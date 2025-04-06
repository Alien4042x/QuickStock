//
//  ApiKey.swift
//  QuickStock
//
//  Created by Radim Veselý on 18.03.2025.
//

import Foundation
import CryptoKit

struct ApiKeyStorage {
    // Computed property: retrieves an existing encryption key or generates a new one and stores it.
    private static var encryptionKey: SymmetricKey {
        let fileManager = FileManager.default
        let keyFile = fileURL.deletingLastPathComponent().appendingPathComponent("EncryptionKey.data")
        if fileManager.fileExists(atPath: keyFile.path) {
            do {
                let keyData = try Data(contentsOf: keyFile)
                return SymmetricKey(data: keyData)
            } catch { }
        }
        let newKey = SymmetricKey(size: .bits128)
        do {
            let keyData = newKey.withUnsafeBytes { Data(Array($0)) }
            try keyData.write(to: keyFile)
        } catch { }
        return newKey
    }
    
    // Path where ApiKey.data is stored in the Documents/QuickStock folder
    private static var fileURL: URL {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = documents.appendingPathComponent("QuickStock", isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            do {
                try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            } catch { }
        }
        return folder.appendingPathComponent("ApiKey.data")
    }
    
    // Saves the API key: first it is encrypted using encryptionKey, then it is saved to a file.
    static func saveApiKey(_ apiKey: String) {
        guard let plainData = apiKey.data(using: .utf8) else { return }
        do {
            let sealedBox = try AES.GCM.seal(plainData, using: encryptionKey)
            if let combinedData = sealedBox.combined {
                try combinedData.write(to: fileURL)
            }
        } catch { }
    }
    
    // Retrieves and decrypts the API key from the file.
    static func loadApiKey() -> String? {
        do {
            let encryptedData = try Data(contentsOf: fileURL)
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
            let apiKey = String(data: decryptedData, encoding: .utf8)
            return apiKey
        } catch {
            return nil
        }
    }
    
    // Deletes the saved API key.
    static func deleteApiKey() {
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch { }
    }
}
