//
//  QuickStockApp.swift
//  QuickStock
//
//  Created by Radim Veselý on 08.03.2025.
//

import SwiftUI
import SwiftUI

@main
struct QuickStockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 450, minHeight: 350)
        }
        
        .commands {
            CommandGroup(replacing: .appSettings) {
                Menu("Settings") {
                    Button("API Key") {
                        NotificationCenter.default.post(name: .showApiKeySettings, object: nil)
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
            }
            CommandGroup(replacing: .appInfo) {
                Button("About QuickStock") {
                    showCustomAboutWindow()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowToolbarStyle(UnifiedCompactWindowToolbarStyle())
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
