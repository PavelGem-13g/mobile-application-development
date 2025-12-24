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

    var body: some View {
        NavigationStack {
            Form {
                connectionSection
                modelSection
                promptSection
                responseSection
            }
            .navigationTitle("Домашний LLM")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        recordMetric(event: "tap_refresh_models", status: "ok")
                        Task { await viewModel.refreshModels(baseURL: gatewayBaseURL, token: gatewayToken) }
                    } label: {
                        if viewModel.isLoadingModels {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .accessibilityIdentifier("refreshModelsButton")
                    .disabled(viewModel.isLoadingModels)
                }
            }
            .task {
                await viewModel.refreshModels(baseURL: gatewayBaseURL, token: gatewayToken)
            }
            .onAppear {
                recordMetric(event: "view_content_loaded", status: "ok")
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
                feedbackSheet
            }
        }
    }

    private var connectionSection: some View {
        Section("Подключение") {
            TextField("Gateway URL", text: $gatewayBaseURL)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .accessibilityIdentifier("gatewayURLField")
            SecureField("Токен (если задан)", text: $gatewayToken)
                .accessibilityIdentifier("gatewayTokenField")
            HStack {
                Label(viewModel.connectionState.description, systemImage: statusIcon)
                    .foregroundStyle(statusTint)
                    .accessibilityIdentifier("connectionStatusLabel")
                Spacer()
                if viewModel.isLoadingModels {
                    ProgressView()
                }
            }
            Button("Проверить соединение") {
                recordMetric(event: "tap_check_connection", status: "ok")
                Task { await viewModel.refreshModels(baseURL: gatewayBaseURL, token: gatewayToken) }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("checkConnectionButton")
        }
    }

    private var modelSection: some View {
        Section("Модель") {
            if viewModel.models.isEmpty {
                Text("Нет доступных моделей. Проверь дом. ПК и Ollama.")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Модель", selection: $viewModel.selectedModelID) {
                    ForEach(viewModel.models) { model in
                        Text(model.name).tag(Optional(model.id))
                    }
                }
                .accessibilityIdentifier("modelPicker")
            }
        }
    }

    private var promptSection: some View {
        Section("Промпт") {
            TextEditor(text: $viewModel.prompt)
                .frame(minHeight: 150)
                .focused($promptFocused)
                .accessibilityIdentifier("promptEditor")
            Button {
                recordMetric(event: "tap_send_prompt", status: "ok")
                promptFocused = false
                Task { await viewModel.sendPrompt(baseURL: gatewayBaseURL, token: gatewayToken) }
            } label: {
                Group {
                    if viewModel.isSending {
                        ProgressView()
                    } else {
                        Text("Отправить")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSending)
            .accessibilityIdentifier("sendPromptButton")
        }
    }

    private var responseSection: some View {
        Section("Ответ") {
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("errorText")
            }
            if viewModel.responseText.isEmpty {
                Text("Ответ появится здесь.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("responsePlaceholderText")
            } else {
                ScrollView {
                    Text(viewModel.responseText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("responseText")
                }
            }
        }
    }

    private var feedbackSheet: some View {
        NavigationStack {
            Form {
                Section("Оцените качество") {
                    Picker("Оценка", selection: $feedbackRating) {
                        ForEach(1 ... 5, id: \.self) { value in
                            Text("\(value)")
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Комментарий") {
                    TextEditor(text: $feedbackComment)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Ваш отзыв")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Позже") {
                        isFeedbackPresented = false
                        recordMetric(event: "feedback_skipped", status: "ok")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Отправить") {
                        submitFeedback()
                        isFeedbackPresented = false
                    }
                }
            }
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
