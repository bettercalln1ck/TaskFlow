import SwiftUI

struct FilterSortBar: View {
    @Binding var query: TaskQuery
    let onChange: () -> Void

    var body: some View {
        HStack {
            Menu {
                Picker("Category", selection: $query.category) {
                    Text("All Categories").tag(TaskCategory?.none)
                    ForEach(TaskCategory.allCases) { Text($0.title).tag(TaskCategory?.some($0)) }
                }
                Picker("Status", selection: $query.status) {
                    Text("All Statuses").tag(TaskStatus?.none)
                    ForEach(TaskStatus.allCases) { Text($0.title).tag(TaskStatus?.some($0)) }
                }
            } label: { Label("Filter", systemImage: "line.3.horizontal.decrease.circle") }

            Spacer()

            Menu {
                Picker("Sort", selection: $query.sort) {
                    ForEach(TaskSort.allCases) { Text($0.title).tag($0) }
                }
            } label: { Label("Sort", systemImage: "arrow.up.arrow.down.circle") }
        }
        .padding(.horizontal)
        .onChange(of: query) { _, _ in onChange() }
    }
}
