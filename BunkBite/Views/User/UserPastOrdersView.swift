//
//  UserPastOrdersView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct UserPastOrdersView: View {
    @State private var showContent = false

    var body: some View {
        ZStack {
            Constants.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Past Orders")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Constants.textColor)

                    Spacer()

                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 24))
                            .foregroundColor(Constants.textColor)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .opacity(showContent ? 1 : 0)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(0..<5, id: \.self) { index in
                            OrderCard(orderNumber: "#\(10000 + index)", date: "Nov \(index + 1), 2025", status: index % 3 == 0 ? "Delivered" : "Completed", items: 3, total: "₹\(150 + index * 20)")
                                .offset(y: showContent ? 0 : 30)
                                .opacity(showContent ? 1 : 0)
                                .animation(Constants.bouncyAnimation.delay(Double(index) * 0.1), value: showContent)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
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

struct OrderCard: View {
    let orderNumber: String
    let date: String
    let status: String
    let items: Int
    let total: String
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
            }
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(orderNumber)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Constants.textColor)

                        Text(date)
                            .font(.system(size: 14))
                            .foregroundColor(Constants.darkGray)
                    }

                    Spacer()

                    Text(status)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(status == "Delivered" ? Color.green : Constants.primaryColor)
                        .cornerRadius(12)
                }

                Divider()

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

                HStack {
                    Button(action: {}) {
                        Text("Reorder")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Constants.primaryColor)
                            .cornerRadius(12)
                    }

                    Button(action: {}) {
                        Text("View Details")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Constants.primaryColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Constants.lightGray)
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
