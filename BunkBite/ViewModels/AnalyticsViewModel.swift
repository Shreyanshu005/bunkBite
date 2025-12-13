//
//  AnalyticsViewModel.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var summary: AnalyticsSummary?
    @Published var earningsData: EarningsData?
    @Published var selectedPeriod: AnalyticsPeriod = .day {
        didSet {
            // Reload data when period changes
            Task {
                await loadData()
            }
        }
    }
    
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiService = APIService.shared
    private let canteenId: String
    private let token: String
    
    init(canteenId: String, token: String) {
        self.canteenId = canteenId
        self.token = token
    }
    
    func loadData() async {
        guard !canteenId.isEmpty, !token.isEmpty else { return }
        
        isLoading = true
        error = nil
        
        do {
            async let summaryTask = apiService.getAnalytics(canteenId: canteenId, period: selectedPeriod.rawValue, token: token)
            async let earningsTask = apiService.getEarnings(canteenId: canteenId, period: selectedPeriod.rawValue, token: token)
            
            let (fetchedSummary, fetchedEarnings) = try await (summaryTask, earningsTask)
            
            summary = fetchedSummary
            earningsData = fetchedEarnings
        } catch {
            self.error = "Failed to load analytics: \(error.localizedDescription)"
            print("❌ Analytics Load Error: \(error)")
        }
        
        isLoading = false
    }
    
    // Computes max value for chart scaling
    var maxEarnings: Double {
        guard let data = earningsData?.dailyEarnings, !data.isEmpty else { return 100 }
        return (data.map { $0.amount }.max() ?? 100) * 1.2 // Add 20% buffer
    }
}
