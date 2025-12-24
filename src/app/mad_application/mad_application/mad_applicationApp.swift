//
//  mad_applicationApp.swift
//  mad_application
//
//  Created by Павел on 13.12.2025.
//

import SwiftUI

@main
struct mad_applicationApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("gateway_base_url") private var gatewayBaseURL = "http://localhost:8000"
    @AppStorage("gateway_token") private var gatewayToken = ""
    @State private var sessionStart: Date?

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                sessionStart = Date()
                MetricsReporter.shared.record(
                    event: "app_active",
                    durationMs: nil,
                    status: "ok",
                    baseURL: gatewayBaseURL,
                    token: gatewayToken
                )
            case .inactive, .background:
                if let start = sessionStart {
                    MetricsReporter.shared.record(
                        event: "session_duration",
                        durationMs: Date().timeIntervalSince(start) * 1000,
                        status: "ok",
                        baseURL: gatewayBaseURL,
                        token: gatewayToken
                    )
                    sessionStart = nil
                }
            @unknown default:
                break
            }
        }
    }
}
