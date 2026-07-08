import Foundation

enum TaskStatus: String, CaseIterable, Codable, Sendable, Identifiable {
    case pending, completed

    var id: String { rawValue }
    var title: String {
        switch self {
        case .pending: "Pending"; case .completed: "Completed"
        }
    }
}
