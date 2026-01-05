//
//  DateFormatter+Extensions.swift
//  BunkBite
//
//  Created by Antigravity on 30/12/25.
//

import Foundation

extension DateFormatter {
    static func formatOrderDate(_ dateString: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = inputFormatter.date(from: dateString) else {
            // Fallback for strings without fractional seconds
            let fallbackFormatter = ISO8601DateFormatter()
            guard let fallbackDate = fallbackFormatter.date(from: dateString) else {
                return dateString
            }
            return prettyPrint(fallbackDate)
        }
        
        return prettyPrint(date)
    }
    
    private static func prettyPrint(_ date: Date) -> String {
        let formatter = DateFormatter()
        // Format: "30 Dec, 02:53 AM"
        formatter.dateFormat = "d MMM, hh:mm a"
        return formatter.string(from: date)
    }
}
