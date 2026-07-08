import SwiftUI

struct TaskEditorView: View {
    @StateObject var viewModel: TaskEditorViewModel
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var hasDueDate = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $viewModel.title)
                    TextField("Notes", text: $viewModel.details, axis: .vertical).lineLimit(3...6)
                }
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate.animation())
                    if hasDueDate {
                        DatePicker("Due", selection: Binding(
                            get: { viewModel.dueDate ?? Date() },
                            set: { viewModel.dueDate = $0 }), displayedComponents: [.date, .hourAndMinute])
                    }
                }
                Section {
                    Picker("Priority", selection: $viewModel.priority) {
                        ForEach(TaskPriority.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(TaskCategory.allCases) { Label($0.title, systemImage: $0.systemImage).tag($0) }
                    }
                }
                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red).font(.footnote)
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { if await viewModel.save() { onSaved(); dismiss() } }
                    }.disabled(viewModel.isSaving)
                }
            }
            .onAppear { hasDueDate = viewModel.dueDate != nil }
        }
    }
}
