//
//  OwnerOrdersView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct OwnerOrdersView: View {
    @State private var showContent = false
    @State private var selectedFilter = 0

    let filters = ["All", "Pending", "Preparing", "Ready", "Completed"]

    var body: some View {
        ZStack {
            Constants.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Orders")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Constants.textColor)

                    Spacer()

                    Button(action: {}) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20))
                            .foregroundColor(Constants.textColor)
                            .padding(10)
                            .background(Constants.lightGray)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .opacity(showContent ? 1 : 0)

                // Stats
                HStack(spacing: 12) {
                    OrderStatsCard(title: "Pending", count: "8", color: .orange)
                    OrderStatsCard(title: "Preparing", count: "5", color: .blue)
                    OrderStatsCard(title: "Ready", count: "3", color: .green)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .offset(y: showContent ? 0 : -20)
                .opacity(showContent ? 1 : 0)

                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<filters.count, id: \.self) { index in
                            FilterChip(
                                title: filters[index],
                                isSelected: selectedFilter == index
                            ) {
                                withAnimation(Constants.quickBounce) {
                                    selectedFilter = index
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, 16)

                // Orders List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(0..<10, id: \.self) { index in
                            OwnerOrderCard(
                                orderNumber: "#\(10000 + index)",
                                customerName: "Customer \(index + 1)",
                                items: 3,
                                total: "₹\(150 + index * 20)",
                                time: "\(5 + index) min ago",
                                status: index % 4 == 0 ? "Pending" : (index % 3 == 0 ? "Preparing" : "Ready")
                            )
                            .offset(y: showContent ? 0 : 30)
                            .opacity(showContent ? 1 : 0)
                            .animation(Constants.bouncyAnimation.delay(Double(index) * 0.05), value: showContent)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }
}

struct OrderStatsCard: View {
    let title: String
    let count: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(count)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Constants.darkGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(Constants.quickBounce) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(Constants.quickBounce) {
                    isPressed = false
                }
                action()
            }
        }) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Constants.textColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Constants.primaryColor : Constants.lightGray)
                .cornerRadius(20)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
    }
}

struct OwnerOrderCard: View {
    let orderNumber: String
    let customerName: String
    let items: Int
    let total: String
    let time: String
    let status: String
    @State private var isPressed = false

    var statusColor: Color {
        switch status {
        case "Pending": return .orange
        case "Preparing": return .blue
        case "Ready": return .green
        default: return Constants.primaryColor
        }
    }

    var body: some View {
        Button(action: {
            withAnimation(Constants.quickBounce) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(Constants.quickBounce) {
                    isPressed = false
                }
            }
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(orderNumber)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Constants.textColor)

                            Circle()
                                .fill(Constants.darkGray)
                                .frame(width: 4, height: 4)

                            Text(time)
                                .font(.system(size: 13))
                                .foregroundColor(Constants.darkGray)
                        }

                        Text(customerName)
                            .font(.system(size: 14))
                            .foregroundColor(Constants.darkGray)
                    }

                    Spacer()

                    Text(status)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(statusColor)
                        .cornerRadius(12)
                }

                Divider()

                // Order Details
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Constants.darkGray)
                        Text("\(items) items")
                            .font(.system(size: 14))
                            .foregroundColor(Constants.darkGray)
                    }

                    Spacer()

                    Text(total)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Constants.primaryColor)
                }

                // Action Buttons
                if status == "Pending" {
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            Text("Accept")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Constants.primaryColor)
                                .cornerRadius(12)
                        }

                        Button(action: {}) {
                            Text("Reject")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Constants.primaryColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Constants.lightGray)
                                .cornerRadius(12)
                        }
                    }
                } else if status == "Preparing" {
                    Button(action: {}) {
                        Text("Mark as Ready")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(statusColor)
                            .cornerRadius(12)
                    }
                } else if status == "Ready" {
                    Button(action: {}) {
                        Text("Mark as Delivered")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(statusColor)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
    }
}
