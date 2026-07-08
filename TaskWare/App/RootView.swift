import SwiftUI

struct RootView: View {
    let container: AppContainer
    @StateObject private var auth: AuthViewModel
    @StateObject private var dashboard: DashboardViewModel

    init(container: AppContainer) {
        self.container = container
        _auth = StateObject(wrappedValue: AuthViewModel(authService: container.authService, authStore: container.authStore))
        _dashboard = StateObject(wrappedValue: DashboardViewModel(repository: container.taskRepository, notifications: container.notificationService))
    }

    var body: some View {
        Group {
            if auth.authenticatedUser != nil {
                DashboardView(viewModel: dashboard, container: container) { auth.logout() }
            } else {
                LoginView(viewModel: auth)
            }
        }
        .animation(.default, value: auth.authenticatedUser)
        .task {
            auth.restoreSession()
            await container.notificationService.requestAuthorization()
        }
    }
}
