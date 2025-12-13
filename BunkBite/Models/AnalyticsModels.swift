//
//  AnalyticsModels.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import Foundation

// MARK: - Analytics Types

enum AnalyticsPeriod: String, CaseIterable {
    case day = "day"
    case week = "week"
    case month = "month"
    
    var title: String {
        switch self {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        }
    }
}

// MARK: - API Response Models

struct AnalyticsSummary: Codable {
    let totalEarnings: Double
    let totalOrders: Int
    let averageOrderValue: Double
    let ordersByStatus: OrderStatusBreakdown
    let topItems: [TopItem]
}

struct OrderStatusBreakdown: Codable {
    let paid: Int
    let preparing: Int
    let ready: Int
    let completed: Int
    let cancelled: Int
}

struct TopItem: Codable, Identifiable {
    let id: String
    let name: String
    let quantity: Int
    let revenue: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, quantity, revenue
    }
}

struct EarningsData: Codable {
    let dailyEarnings: [DailyEarning]
    let totalEarnings: Double
}

struct DailyEarning: Codable, Identifiable {
    let date: String // Format: YYYY-MM-DD
    let amount: Double
    
    var id: String { date }
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let dateObj = formatter.date(from: date) {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: dateObj)
        }
        return date
    }
}
