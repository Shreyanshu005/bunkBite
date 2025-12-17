//
//  NotificationManager.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import UserNotifications
import UIKit

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            } else {
                print("⚠️ Notification permission denied")
            }
        }
    }
    
    func sendOrderPlacedNotification(orderId: String, canteenName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Order Placed Successfully! 🎉"
        content.body = "Your order #\(orderId.suffix(6)) at \(canteenName) has been confirmed. You can pick up your order now!"
        content.sound = .default
        
        // Trigger immediately (time interval must be > 0)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("✅ Order placed notification scheduled")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Allow notification to show even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}
