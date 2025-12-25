import SwiftUI

struct FeedbackSheetView: View {
    @Binding var rating: Int
    @Binding var comment: String
    let onSkip: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Оцените качество") {
                    Picker("Оценка", selection: $rating) {
                        ForEach(1 ... 5, id: \.self) { value in
                            Text("\(value)")
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Комментарий") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Ваш отзыв")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Позже", action: onSkip)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Отправить", action: onSubmit)
                }
            }
        }
    }
}
