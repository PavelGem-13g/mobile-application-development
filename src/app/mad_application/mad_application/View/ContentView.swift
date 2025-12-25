//
//  ContentView.swift
//  mad_application
//
//  Created by Павел on 13.12.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @AppStorage("gateway_base_url") private var gatewayBaseURL = "http://localhost:8000"
    @AppStorage("gateway_token") private var gatewayToken = ""
    @FocusState private var promptFocused: Bool
    @State private var isFeedbackPresented = false
    @State private var feedbackRating = 4
    @State private var feedbackComment = ""
    @AppStorage("feedback_last_prompt_time") private var feedbackLastPromptTime: Double = 0
    @AppStorage("feedback_prompt_count") private var feedbackPromptCount: Int = 0
    @State private var feedbackTask: Task<Void, Never>?
    @State private var isSettingsPresented = false
    @State private var isHistoryPresented = false
    @State private var backgroundShift = false

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackgroundView(backgroundShift: backgroundShift)
                VStack(spacing: 16) {
                    ChatHeaderView(
                        title: "Домашний LLM",
                        modelName: viewModel.selectedModelID ?? "Модель не выбрана",
                        statusTint: statusTint,
                        onHistory: { isHistoryPresented = true },
                        onSettings: { isSettingsPresented = true }
                    )
                    ChatAreaView(messages: viewModel.currentMessages, isSending: viewModel.isSending)
                    ChatInputBarView(
                        prompt: $viewModel.prompt,
                        selectedModelID: $viewModel.selectedModelID,
                        promptFocused: $promptFocused,
                        isSending: viewModel.isSending,
                        models: viewModel.models,
                        onRefreshModels: {
                            recordMetric(event: "tap_refresh_models", status: "ok")
                            Task { await viewModel.refreshModels(baseURL: gatewayBaseURL, token: gatewayToken) }
                        },
                        onSend: sendPrompt
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.refreshModels(baseURL: gatewayBaseURL, token: gatewayToken)
            }
            .onAppear {
                recordMetric(event: "view_content_loaded", status: "ok")
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    backgroundShift.toggle()
                }
            }
            .onChange(of: viewModel.selectedModelID) { _, newValue in
                if newValue != nil {
                    recordMetric(event: "model_selected", status: "ok")
                }
            }
            .onChange(of: viewModel.connectionState) { _, newValue in
                let status: String
                switch newValue {
                case .connected:
                    status = "connected"
                case .connecting:
                    status = "connecting"
                case .failed:
                    status = "failed"
                case .idle:
                    status = "idle"
                }
                recordMetric(event: "connection_state", status: status)
            }
            .onChange(of: viewModel.responseText) { _, newValue in
                guard !newValue.isEmpty else { return }
                guard shouldPromptForFeedback() else { return }
                feedbackTask?.cancel()
                feedbackTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 10_000_000_000)
                    feedbackLastPromptTime = Date().timeIntervalSince1970
                    feedbackPromptCount += 1
                    isFeedbackPresented = true
                    recordMetric(event: "feedback_prompt_shown", status: "ok")
                }
            }
            .sheet(isPresented: $isFeedbackPresented) {
                FeedbackSheetView(
                    rating: $feedbackRating,
                    comment: $feedbackComment,
                    onSkip: {
                        isFeedbackPresented = false
                        recordMetric(event: "feedback_skipped", status: "ok")
                    },
                    onSubmit: {
                        submitFeedback()
                        isFeedbackPresented = false
                    }
                )
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsSheetView(
                    backgroundShift: backgroundShift,
                    gatewayBaseURL: $gatewayBaseURL,
                    gatewayToken: $gatewayToken,
                    models: viewModel.models,
                    selectedModelID: $viewModel.selectedModelID,
                    connectionStatusText: viewModel.connectionState.description,
                    statusIcon: statusIcon,
                    statusTint: statusTint,
                    isLoadingModels: viewModel.isLoadingModels,
                    onRefreshModels: {
                        recordMetric(event: "tap_check_connection", status: "ok")
                        Task { await viewModel.refreshModels(baseURL: gatewayBaseURL, token: gatewayToken) }
                    },
                    onDone: { isSettingsPresented = false }
                )
            }
            .sheet(isPresented: $isHistoryPresented) {
                HistorySheetView(
                    backgroundShift: backgroundShift,
                    sessions: viewModel.sessions,
                    selectedSessionID: viewModel.selectedSessionID,
                    onCreate: {
                        viewModel.createNewSession()
                        isHistoryPresented = false
                    },
                    onSelect: { id in
                        viewModel.selectSession(id)
                        isHistoryPresented = false
                    },
                    onDelete: { id in
                        viewModel.deleteSession(id)
                    },
                    onDone: { isHistoryPresented = false }
                )
            }
        }
    }

    private func sendPrompt() {
        recordMetric(event: "tap_send_prompt", status: "ok")
        promptFocused = false
        Task {
            await viewModel.sendPromptStream(baseURL: gatewayBaseURL, token: gatewayToken)
        }
    }

    private func recordMetric(event: String, status: String) {
        MetricsReporter.shared.record(
            event: event,
            durationMs: nil,
            status: status,
            baseURL: gatewayBaseURL,
            token: gatewayToken
        )
    }

    private func shouldPromptForFeedback() -> Bool {
        if ProcessInfo.processInfo.environment["UITEST_MOCK"] == "1" {
            return false
        }
        return true
    }

    private func submitFeedback() {
        FeedbackReporter.shared.send(
            rating: feedbackRating,
            comment: feedbackComment.isEmpty ? nil : feedbackComment,
            scenario: "chat_completed",
            baseURL: gatewayBaseURL,
            token: gatewayToken
        )
        recordMetric(event: "feedback_submitted", status: "ok")
        feedbackComment = ""
        feedbackRating = 4
    }

    private var statusIcon: String {
        switch viewModel.connectionState {
        case .connected:
            return "checkmark.circle"
        case .connecting:
            return "arrow.triangle.2.circlepath"
        case .failed:
            return "exclamationmark.triangle"
        case .idle:
            return "questionmark.circle"
        }
    }

    private var statusTint: Color {
        switch viewModel.connectionState {
        case .connected:
            return .green
        case .connecting:
            return .blue
        case .failed:
            return .orange
        case .idle:
            return .secondary
        }
    }
}

#Preview {
    ContentView()
}
