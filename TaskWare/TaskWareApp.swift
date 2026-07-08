import SwiftUI

@main
struct TaskWareApp: App {
    @State private var container = AppContainer()
    var body: some Scene {
        WindowGroup { RootView(container: container) }
    }
}
