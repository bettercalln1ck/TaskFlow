import Foundation

enum TaskCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case work, personal, shopping, health, other

    var id: String { rawValue }
    var title: String {
        switch self {
        case .work: "Work"; case .personal: "Personal"; case .shopping: "Shopping"
        case .health: "Health"; case .other: "Other"
        }
    }
    var systemImage: String {
        switch self {
        case .work: "briefcase"; case .personal: "person"; case .shopping: "cart"
        case .health: "heart"; case .other: "tray"
        }
    }
}
