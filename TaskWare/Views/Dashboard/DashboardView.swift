import SwiftUI
import UIKit

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let container: AppContainer
    let onLogout: () -> Void

    @State private var editorMode: TaskEditorViewModel.Mode?
    @State private var now = Date()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                content
                if viewModel.recentlyDeleted != nil {
                    UndoSnackbar(message: "Task deleted") {
                        Task { await viewModel.undoLastDelete() }
                    }
                    .task { // auto-dismiss after 5s
                        try? await _Concurrency.Task.sleep(for: .seconds(5))
                        viewModel.clearUndo()
                    }
                }
            }
            .navigationTitle("Tasks")
            .searchable(text: $viewModel.query.searchText, prompt: "Search by title")
            .onChange(of: viewModel.query.searchText) { _, _ in Task { await viewModel.applyQuery() } }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Log Out", role: .destructive, action: onLogout)
                        #if DEBUG
                        Button("Seed 1,000 tasks") {
                            Task { await DebugSeeder.seed(1000, into: container.taskRepository, now: Date()); await viewModel.refresh() }
                        }
                        #endif
                    }
                    label: { Image(systemName: "person.circle") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editorMode = .create } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add task")
                }
            }
            .sheet(item: $editorMode) { mode in
                TaskEditorView(viewModel: TaskEditorViewModel(
                    mode: mode, repository: container.taskRepository,
                    notifications: container.notificationService)) {
                        Task { await viewModel.refresh() }
                    }
            }
            .task { now = Date(); await viewModel.load() }
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading: LoadingView()
        case .empty: EmptyStateView()
        case .failed(let message): ErrorStateView(message: message) { Task { await viewModel.load() } }
        case .loaded:
            List {
                Section { InsightsHeader(insights: viewModel.insights).listRowInsets(EdgeInsets()) }
                Section {
                    FilterSortBar(query: $viewModel.query) { Task { await viewModel.applyQuery() } }
                        .listRowInsets(EdgeInsets())
                }
                if viewModel.tasks.isEmpty {
                    ContentUnavailableView.search
                } else {
                    ForEach(viewModel.tasks) { task in
                        TaskRow(task: task, now: now) {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            Task { await viewModel.toggleComplete(task) }
                        }
                            .contentShape(Rectangle())
                            .onTapGesture { editorMode = .edit(task) }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { Task { await viewModel.delete(task) } }
                                    label: { Label("Delete", systemImage: "trash") }
                            }
                            .swipeActions(edge: .leading) {
                                Button { Task { await viewModel.duplicate(task) } }
                                    label: { Label("Duplicate", systemImage: "plus.square.on.square") }.tint(.blue)
                            }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable { await viewModel.refresh() }
            .animation(.default, value: viewModel.tasks)
        }
    }
}

extension TaskEditorViewModel.Mode: Identifiable {
    var id: String { switch self { case .create: "create"; case .edit(let t): t.id.uuidString } }
}
