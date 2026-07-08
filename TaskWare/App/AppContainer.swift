import Foundation

/// Composition root. Constructs and holds long-lived dependencies.
@MainActor
final class AppContainer {
    let taskRepository: TaskRepository
    let authService: AuthService
    let authStore: AuthStore
    let notificationService: NotificationScheduling

    init() {
        let stack = CoreDataStack()
        self.taskRepository = CoreDataTaskRepository(stack: stack)
        let store = UserDefaultsAuthStore()
        self.authStore = store
        self.authService = LocalAuthService(store: store)
        self.notificationService = NotificationService()
    }

    /// Test/preview seam.
    init(taskRepository: TaskRepository,
         authService: AuthService,
         authStore: AuthStore,
         notificationService: NotificationScheduling) {
        self.taskRepository = taskRepository
        self.authService = authService
        self.authStore = authStore
        self.notificationService = notificationService
    }
}
