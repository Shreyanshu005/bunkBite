//
//  AnalyticsView.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel: AnalyticsViewModel
    @Environment(\.dismiss) var dismiss
    
    init(canteenId: String, token: String) {
        _viewModel = StateObject(wrappedValue: AnalyticsViewModel(canteenId: canteenId, token: token))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Period Selector
                Picker("Period", selection: $viewModel.selectedPeriod) {
                    ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(height: 200)
                } else if let error = viewModel.error {
                    ContentUnavailableView {
                        Label("Error Loading Data", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task { await viewModel.loadData() }
                        }
                    }
                } else if let summary = viewModel.summary {
                    // Key Metrics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        MetricCard(
                            title: "Total Revenue",
                            value: "₹\(Int(summary.totalEarnings))",
                            icon: "indianrupeesign.circle.fill",
                            color: .green
                        )
                        
                        MetricCard(
                            title: "Total Orders",
                            value: "\(summary.totalOrders)",
                            icon: "cart.fill",
                            color: .blue
                        )
                        
                        MetricCard(
                            title: "Avg. Order Value",
                            value: "₹\(Int(summary.averageOrderValue))",
                            icon: "chart.pie.fill",
                            color: .orange
                        )
                        
                        MetricCard(
                            title: "Cancelled",
                            value: "\(summary.ordersByStatus.cancelled)",
                            icon: "xmark.circle.fill",
                            color: .red
                        )
                    }
                    .padding(.horizontal)
                    
                    // Earnings Chart
                    if let earnings = viewModel.earningsData, !earnings.dailyEarnings.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Earnings Trend")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Chart {
                                ForEach(earnings.dailyEarnings) { data in
                                    BarMark(
                                        x: .value("Date", data.displayDate),
                                        y: .value("Earnings", data.amount)
                                    )
                                    .foregroundStyle(Constants.primaryColor.gradient)
                                }
                            }
                            .frame(height: 200)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Top Items List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Selling Items")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ForEach(summary.topItems) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("\(item.quantity) units sold")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("₹\(Int(item.revenue))")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Constants.primaryColor)
                                }
                                .padding()
                                
                                if item.id != summary.topItems.last?.id {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Analytics")
        .task {
            await viewModel.loadData()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}
