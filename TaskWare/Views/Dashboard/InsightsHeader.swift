import SwiftUI

struct InsightsHeader: View {
    let insights: TaskInsights
    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            stat("Total", insights.total, .blue)
            stat("Done", insights.completed, .green)
            stat("Pending", insights.pending, .orange)
            stat("Overdue", insights.overdue, .red)
        }
        .padding(.horizontal)
        .padding(.vertical)
    }

    private func stat(_ title: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.title2.bold()).foregroundStyle(color)
                .contentTransition(.numericText())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(title) tasks")
    }
}
