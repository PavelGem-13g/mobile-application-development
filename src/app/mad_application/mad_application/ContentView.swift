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
    @AppStorage("chat_sessions_v1") private var sessionsData = Data()
    @AppStorage("chat_selected_session_id") private var selectedSessionIDRaw: String = ""
    @State private var feedbackTask: Task<Void, Never>?
    @State private var isSettingsPresented = false
    @State private var isHistoryPresented = false
    @State private var sessions: [ChatSession] = []
    @State private var selectedSessionID: UUID?
    @State private var streamingMessageID: UUID?
    @State private var backgroundShift = false

    var body: some View {
        NavigationStack {
            ZStack {
                animatedBackground
                VStack(spacing: 16) {
                    header
                    chatArea
                    inputBar
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
                loadSessions()
                ensureSessionExists()
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    backgroundShift.toggle()
                }
            }
            .onChange(of: sessions) { _, _ in
                saveSessions()
            }
            .onChange(of: selectedSessionID) { _, _ in
                saveSessions()
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
            .onChange(of: viewModel.errorMessage) { _, newValue in
                guard let message = newValue, !message.isEmpty else { return }
                appendSystemMessage(message)
            }
            .sheet(isPresented: $isFeedbackPresented) {
                feedbackSheet
            }
            .sheet(isPresented: $isSettingsPresented) {
                settingsSheet
            }
            .sheet(isPresented: $isHistoryPresented) {
                historySheet
            }
        }
    }

    private var animatedBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.1, blue: 0.16),
                Color(red: 0.12, green: 0.18, blue: 0.28),
                Color(red: 0.18, green: 0.2, blue: 0.32)
            ],
            startPoint: backgroundShift ? .topLeading : .bottomLeading,
            endPoint: backgroundShift ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .overlay(
            RadialGradient(
                colors: [Color.white.opacity(0.14), Color.clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 220
            )
            .blendMode(.screen)
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Домашний LLM")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                HStack(spacing: 8) {
                    StatusDot(tint: statusTint)
                    Text(viewModel.selectedModelID ?? "Модель не выбрана")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .layoutPriority(1)
            Spacer()
            Button {
                isHistoryPresented = true
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityIdentifier("historyButton")
            Button {
                isSettingsPresented = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityIdentifier("settingsButton")
        }
    }

    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    if currentMessages.isEmpty {
                        welcomeCard
                            .transition(.opacity)
                    }
                    ForEach(currentMessages) { message in
                        MessageBubble(message: message)
                            .transition(.move(edge: message.role == .user ? .trailing : .leading)
                                .combined(with: .opacity))
                    }
                    if viewModel.isSending {
                        typingBubble
                            .transition(.opacity)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .onChange(of: currentMessages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isSending) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var inputBar: some View {
        VStack(spacing: 10) {
            HStack {
                Menu {
                    Button("Обновить модели") {
                        recordMetric(event: "tap_refresh_models", status: "ok")
                        Task { await viewModel.refreshModels(baseURL: gatewayBaseURL, token: gatewayToken) }
                    }
                    .accessibilityIdentifier("refreshModelsButton")
                    ForEach(viewModel.models) { model in
                        Button {
                            viewModel.selectedModelID = model.id
                        } label: {
                            if model.id == viewModel.selectedModelID {
                                Label(model.name, systemImage: "checkmark")
                            } else {
                                Text(model.name)
                            }
                        }
                    }
                } label: {
                    Label(viewModel.selectedModelID ?? "Выбрать модель", systemImage: "cpu")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .accessibilityIdentifier("modelPicker")
                Spacer()
            }
            HStack(alignment: .bottom, spacing: 12) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.prompt)
                        .frame(minHeight: 44, maxHeight: 120)
                        .focused($promptFocused)
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .accessibilityIdentifier("promptEditor")
                    if viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Напишите запрос…")
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                    }
                }
                Button {
                    sendPrompt()
                } label: {
                    Image(systemName: viewModel.isSending ? "paperplane.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(viewModel.isSending ? 20 : 0))
                        .scaleEffect(viewModel.isSending ? 0.9 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isSending)
                }
                .accessibilityIdentifier("sendPromptButton")
                .disabled(viewModel.isSending)
            }
            HStack {
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Привет! Я ваш локальный ассистент")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text("Напишите вопрос, выберите модель и получайте ответы прямо здесь.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .accessibilityIdentifier("responsePlaceholderText")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var typingBubble: some View {
        HStack {
            TypingIndicator()
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
            Spacer()
        }
    }

    private var settingsSheet: some View {
        NavigationStack {
            ZStack {
                animatedBackground
                ScrollView {
                    VStack(spacing: 16) {
                        settingsCard
                        connectionActions
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        isSettingsPresented = false
                    }
                }
            }
        }
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Подключение")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 10) {
                Text("Gateway URL")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                TextField("http://localhost:8000", text: $gatewayBaseURL)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityIdentifier("gatewayURLField")
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Токен")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                SecureField("Если задан", text: $gatewayToken)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityIdentifier("gatewayTokenField")
            }
            Divider().background(Color.white.opacity(0.2))
            Text("Модель")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            VStack(spacing: 8) {
                ForEach(viewModel.models) { model in
                    Button {
                        viewModel.selectedModelID = model.id
                    } label: {
                        HStack {
                            Text(model.name)
                                .foregroundStyle(.white)
                            Spacer()
                            if model.id == viewModel.selectedModelID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityIdentifier("modelPicker")
                }
                if viewModel.models.isEmpty {
                    Text("Нет доступных моделей. Проверьте дом. ПК и Ollama.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var connectionActions: some View {
        VStack(spacing: 12) {
            HStack {
                Label(viewModel.connectionState.description, systemImage: statusIcon)
                    .foregroundStyle(statusTint)
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
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var historySheet: some View {
        NavigationStack {
            ZStack {
                animatedBackground
                ScrollView {
                    VStack(spacing: 12) {
                        Button {
                            createNewSession()
                            isHistoryPresented = false
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Новый чат")
                                Spacer()
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
                        }
                        ForEach(sessions) { session in
                            Button {
                                selectedSessionID = session.id
                                isHistoryPresented = false
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(session.title)
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        if session.id == selectedSessionID {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                        }
                                    }
                                    Text(session.preview)
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.7))
                                        .lineLimit(2)
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteSession(session.id)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("История")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        isHistoryPresented = false
                    }
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

    private func sendPrompt() {
        recordMetric(event: "tap_send_prompt", status: "ok")
        promptFocused = false
        let trimmed = viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            viewModel.errorMessage = "Введите промпт"
            return
        }
        guard let modelID = viewModel.selectedModelID, !modelID.isEmpty else {
            viewModel.errorMessage = "Выберите модель"
            return
        }
        ensureSessionExists()
        appendUserMessage(trimmed)
        let assistantID = appendAssistantMessage("")
        streamingMessageID = assistantID
        viewModel.prompt = ""
        Task {
            await viewModel.sendPromptStream(baseURL: gatewayBaseURL, token: gatewayToken, modelID: modelID, prompt: trimmed) { partial in
                updateStreamingMessage(partial)
            }
            streamingMessageID = nil
        }
    }

    private func ensureSessionExists() {
        if sessions.isEmpty {
            let session = ChatSession(title: "Новый чат", messages: [])
            sessions = [session]
            selectedSessionID = session.id
        } else if selectedSessionID == nil {
            selectedSessionID = sessions.first?.id
        }
    }

    private func createNewSession() {
        let session = ChatSession(title: "Новый чат", messages: [])
        sessions.insert(session, at: 0)
        selectedSessionID = session.id
    }

    private func deleteSession(_ id: UUID) {
        sessions.removeAll { $0.id == id }
        if selectedSessionID == id {
            selectedSessionID = sessions.first?.id
        }
        ensureSessionExists()
    }

    private var currentSessionIndex: Int? {
        sessions.firstIndex { $0.id == selectedSessionID }
    }

    private var currentMessages: [ChatBubbleMessage] {
        guard let index = currentSessionIndex else { return [] }
        return sessions[index].messages
    }

    private func updateCurrentSession(_ update: (inout ChatSession) -> Void) {
        ensureSessionExists()
        guard let index = currentSessionIndex else { return }
        update(&sessions[index])
    }

    private func loadSessions() {
        guard !sessionsData.isEmpty else { return }
        do {
            let decoded = try JSONDecoder().decode([ChatSession].self, from: sessionsData)
            sessions = decoded
            if let storedID = UUID(uuidString: selectedSessionIDRaw),
               decoded.contains(where: { $0.id == storedID }) {
                selectedSessionID = storedID
            } else {
                selectedSessionID = decoded.first?.id
            }
        } catch {
            sessions = []
            selectedSessionID = nil
        }
    }

    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            sessionsData = data
            selectedSessionIDRaw = selectedSessionID?.uuidString ?? ""
        } catch {
            return
        }
    }

    private func appendUserMessage(_ text: String) {
        let message = ChatBubbleMessage(role: .user, text: text)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            updateCurrentSession { session in
                session.messages.append(message)
                if session.title == "Новый чат" {
                    session.title = String(text.prefix(36))
                }
            }
        }
    }

    private func appendAssistantMessage(_ text: String) -> UUID {
        let message = ChatBubbleMessage(role: .assistant, text: text)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            updateCurrentSession { session in
                session.messages.append(message)
            }
        }
        return message.id
    }

    private func updateStreamingMessage(_ text: String) {
        guard let messageID = streamingMessageID else { return }
        updateCurrentSession { session in
            if let index = session.messages.firstIndex(where: { $0.id == messageID }) {
                session.messages[index].text = text
            }
        }
    }

    private func appendSystemMessage(_ text: String) {
        let message = ChatBubbleMessage(role: .system, text: text)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            updateCurrentSession { session in
                session.messages.append(message)
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

private struct ChatSession: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var messages: [ChatBubbleMessage]
    let createdAt: Date

    init(title: String, messages: [ChatBubbleMessage]) {
        self.id = UUID()
        self.title = title
        self.messages = messages
        self.createdAt = Date()
    }

    var preview: String {
        if let last = messages.last {
            return last.text.isEmpty ? "Пустой ответ" : last.text
        }
        return "Новый чат"
    }
}

private struct ChatBubbleMessage: Identifiable, Equatable, Codable {
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    let id: UUID
    let role: Role
    var text: String
    let timestamp: Date

    init(role: Role, text: String) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.timestamp = Date()
    }
}

private struct MessageBubble: View {
    let message: ChatBubbleMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            selectableText
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(message.role == .system ? .white.opacity(0.9) : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(bubbleBackground)
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
                .accessibilityIdentifier(accessibilityID)
            if message.role != .user { Spacer() }
        }
    }

    @ViewBuilder
    private var selectableText: some View {
        if message.role == .assistant {
            renderedText.textSelection(.enabled)
        } else {
            renderedText
        }
    }

    private var renderedText: Text {
        if let attributed = try? AttributedString(
            markdown: message.text,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        ) {
            return Text(attributed)
        }
        return Text(message.text)
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        switch message.role {
        case .user:
            LinearGradient(
                colors: [Color(red: 0.22, green: 0.5, blue: 0.95), Color(red: 0.38, green: 0.7, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        case .assistant:
            Color.white.opacity(0.12)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        case .system:
            Color.orange.opacity(0.3)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private var accessibilityID: String {
        switch message.role {
        case .assistant:
            return "responseText"
        case .system:
            return "errorText"
        case .user:
            return "userText"
        }
    }
}

private struct TypingIndicator: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 6, height: 6)
                        .scaleEffect(0.6 + pulse(at: time, index: index))
                        .opacity(0.4 + pulse(at: time, index: index))
                }
            }
        }
    }

    private func pulse(at time: TimeInterval, index: Int) -> CGFloat {
        let speed = 4.0
        let phase = time * speed + Double(index) * 0.7
        return CGFloat((sin(phase) + 1) / 2) * 0.6
    }
}

private struct StatusDot: View {
    let tint: Color

    var body: some View {
        Circle()
            .fill(tint)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(tint.opacity(0.6), lineWidth: 2)
            )
            .shadow(color: tint.opacity(0.5), radius: 4, x: 0, y: 0)
    }
}

#Preview {
    ContentView()
}
