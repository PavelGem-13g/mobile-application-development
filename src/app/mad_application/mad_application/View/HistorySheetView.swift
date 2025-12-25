import SwiftUI

struct HistorySheetView: View {
    let backgroundShift: Bool
    let sessions: [ChatSession]
    let selectedSessionID: UUID?
    let onCreate: () -> Void
    let onSelect: (UUID) -> Void
    let onDelete: (UUID) -> Void
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackgroundView(backgroundShift: backgroundShift)
                ScrollView {
                    VStack(spacing: 12) {
                        Button(action: onCreate) {
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
                                onSelect(session.id)
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
                                    onDelete(session.id)
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
                    Button("Готово", action: onDone)
                }
            }
        }
    }
}
