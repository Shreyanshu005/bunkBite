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
    let summary: SummaryMetrics
    let ordersByStatus: OrderStatusBreakdown
    let topItems: [TopItem]
    
    enum CodingKeys: String, CodingKey {
        case summary
        case ordersByStatus
        case topItems = "topSellingItems"
    }
    
    // Flattened properties for easier access in View
    var totalEarnings: Double { summary.totalEarnings }
    var totalOrders: Int { summary.totalOrders }
    var averageOrderValue: Double { summary.averageOrderValue }
}

struct SummaryMetrics: Codable {
    let totalEarnings: Double
    let totalOrders: Int
    let averageOrderValue: Double
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decode(Int.self, forKey: .quantity)
        revenue = try container.decode(Double.self, forKey: .revenue)
        
        // Handle missing _id by generating a UUID or using name
        if let decodedId = try? container.decode(String.self, forKey: .id) {
            id = decodedId
        } else {
            id = UUID().uuidString
        }
    }
}

struct EarningsData: Codable {
    let breakdown: [DailyEarning]
    let total: EarningsTotal
    
    // Flatten for ViewModel compatibility
    var dailyEarnings: [DailyEarning] { breakdown }
    var totalEarnings: Double { total.earnings }
}

struct EarningsTotal: Codable {
    let earnings: Double
    let orders: Int
}

struct DailyEarning: Codable, Identifiable {
    let date: String // Format: YYYY-MM-DD
    let earnings: Double
    let orders: Int
    
    // Maintain compatibility with ViewModel which might expect 'amount'
    var amount: Double { earnings }
    
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
