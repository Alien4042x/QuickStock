//
//  AboutView.swift
//  QuickStock
//
//  Created by Radim Veselý on 01.04.2025.
//

import SwiftUI

struct AboutView: View {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1001"
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo
            Image("icon")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .cornerRadius(20)
                .padding(.top, 20)

            Text("QuickStock")
                .font(.system(size: 28, weight: .bold))
            Text("by Alien 4042x")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("Version \(version) (Build \(build))")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        Text("📈 Market Analysis")
                        Text("📊 Financial Ratios")
                        Text("📋 Key Company Metrics")
                    }
                    .font(.body)
                    .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("DEVELOPMENT")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Alien 4042x")
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .frame(width: 520, height: 480)
    }
}

func showCustomAboutWindow() {
    let aboutView = AboutView()
    let hostingController = NSHostingController(rootView: aboutView)

    let window = NSWindow(contentViewController: hostingController)
    window.title = "About"
    window.setContentSize(NSSize(width: 500, height: 400))
    window.styleMask = [.titled, .closable, .miniaturizable]
    window.isReleasedWhenClosed = false
    window.center()
    window.makeKeyAndOrderFront(nil)
}
