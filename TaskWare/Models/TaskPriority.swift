import Foundation

enum TaskPriority: Int16, CaseIterable, Codable, Comparable, Sendable, Identifiable {
    case low = 0, medium = 1, high = 2

    var id: Int16 { rawValue }
    var title: String {
        switch self {
        case .low: "Low"; case .medium: "Medium"; case .high: "High"
        }
    }
    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
