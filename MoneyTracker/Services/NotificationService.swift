

import Foundation
import UserNotifications

@MainActor
final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleBudgetAlert(categoryName: String, percentUsed: Int, budgetID: UUID) {
        let content = UNMutableNotificationContent()
        content.title = "Budget check-in"
        content.body = "You've used \(percentUsed)% of your \(categoryName) budget this month."
        content.sound = .default

     
        let request = UNNotificationRequest(
            identifier: "budget.\(budgetID.uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAlert(for budgetID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["budget.\(budgetID.uuidString)"])
    }
}
