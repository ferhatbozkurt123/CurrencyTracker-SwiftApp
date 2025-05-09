import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        return try await center.requestAuthorization(options: options)
    }
    
    func scheduleNotification(for currency: Currency, threshold: Double) {
        let center = UNUserNotificationCenter.current()
        
        // Önceki bildirimleri temizle
        center.removePendingNotificationRequests(withIdentifiers: [currency.majorCurrency])
        
        let content = UNMutableNotificationContent()
        content.title = "\(currency.name) Değişim Bildirimi"
        
        let changeRatio = abs(currency.changeRatio)
        if changeRatio >= threshold {
            let direction = currency.isPositiveChange ? "yükseldi" : "düştü"
            content.body = "\(currency.name) %\(String(format: "%.2f", changeRatio)) oranında \(direction)"
            content.sound = .default
            
            // Bildirim tetikleyicisi (15 dakikalık kontrol)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 900, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: currency.majorCurrency,
                content: content,
                trigger: trigger
            )
            
            Task {
                do {
                    try await center.add(request)
                } catch {
                    print("Bildirim planlanırken hata: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func checkAndScheduleNotifications(currencies: [Currency], threshold: Double) {
        guard threshold > 0 else { return }
        
        for currency in currencies {
            scheduleNotification(for: currency, threshold: threshold)
        }
    }
    
    func removeAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
} 