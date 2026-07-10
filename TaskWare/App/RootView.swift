import SwiftUI

struct RootView: View {
    let container: AppContainer
    @StateObject private var auth: AuthViewModel

    init(container: AppContainer) {
        self.container = container
        _auth = StateObject(wrappedValue: AuthViewModel(authService: container.authService, authStore: container.authStore))
    }

    var body: some View {
        Group {
            if let user = auth.authenticatedUser {
                DashboardView(container: container, userID: user.id, onLogout: { auth.logout() })
                    .id(user.id)
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
