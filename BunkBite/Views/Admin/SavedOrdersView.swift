//
//  SavedOrdersView.swift
//  BunkBite
//
//  Created by Claude on 16/11/25.
//

import SwiftUI

// MARK: - View to Display Saved Orders (for debugging/testing)
struct SavedOrdersView: View {
    @State private var savedOrders: [OrderSubmission] = []
    @State private var selectedOrder: OrderSubmission?
    @State private var showingJSON = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Constants.primaryColor.opacity(0.05),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if savedOrders.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray.opacity(0.5))

                        Text("No Saved Orders")
                            .font(.urbanist(size: 22, weight: .semibold))
                            .foregroundStyle(.gray)

                        Text("Orders will appear here after payment")
                            .font(.urbanist(size: 15, weight: .regular))
                            .foregroundStyle(.gray.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Header
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Saved Orders")
                                        .font(.urbanist(size: 28, weight: .bold))

                                    Text("\(savedOrders.count) pending orders")
                                        .font(.urbanist(size: 15, weight: .regular))
                                        .foregroundStyle(.gray)
                                }

                                Spacer()

                                Button {
                                    clearAllOrders()
                                } label: {
                                    Text("Clear All")
                                        .font(.urbanist(size: 14, weight: .semibold))
                                        .foregroundStyle(.red)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)

                            // Orders List
                            ForEach(Array(savedOrders.enumerated()), id: \.offset) { index, order in
                                SavedOrderCard(order: order) {
                                    selectedOrder = order
                                    showingJSON = true
                                }
                            }
                            .padding(.horizontal, 24)

                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadOrders()
            }
            .sheet(isPresented: $showingJSON) {
                if let order = selectedOrder {
                    OrderJSONView(order: order)
                }
            }
        }
    }

    private func loadOrders() {
        savedOrders = OrderSubmissionHelper.getSavedOrders()
    }

    private func clearAllOrders() {
        UserDefaults.standard.removeObject(forKey: "pendingOrders")
        savedOrders = []
    }
}

// MARK: - Saved Order Card
struct SavedOrderCard: View {
    let order: OrderSubmission
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(order.canteenName)
                            .font(.urbanist(size: 18, weight: .semibold))
                            .foregroundStyle(.black)

                        Text(order.razorpayPaymentId)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    Text("₹\(Int(order.totalAmount))")
                        .font(.urbanist(size: 22, weight: .bold))
                        .foregroundStyle(Constants.primaryColor)
                }

                Divider()

                // Items
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(order.itemCount) Items")
                        .font(.urbanist(size: 14, weight: .semibold))
                        .foregroundStyle(.gray)
                        .textCase(.uppercase)

                    ForEach(Array(order.items.prefix(3).enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text("\(item.quantity)x")
                                .font(.urbanist(size: 14, weight: .medium))
                                .foregroundStyle(.gray)
                                .frame(width: 30, alignment: .leading)

                            Text(item.name)
                                .font(.urbanist(size: 14, weight: .regular))
                                .foregroundStyle(.black)

                            Spacer()

                            Text("₹\(Int(item.totalPrice))")
                                .font(.urbanist(size: 14, weight: .medium))
                                .foregroundStyle(.gray)
                        }
                    }

                    if order.items.count > 3 {
                        Text("+\(order.items.count - 3) more items")
                            .font(.urbanist(size: 13, weight: .regular))
                            .foregroundStyle(.gray.opacity(0.7))
                            .padding(.top, 4)
                    }
                }

                // Footer
                HStack {
                    Label {
                        Text(formatDate(order.paymentCompletedAt))
                            .font(.urbanist(size: 13, weight: .regular))
                            .foregroundStyle(.gray)
                    } icon: {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    Text("View JSON →")
                        .font(.urbanist(size: 13, weight: .semibold))
                        .foregroundStyle(Constants.primaryColor)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Order JSON View
struct OrderJSONView: View {
    let order: OrderSubmission
    @Environment(\.dismiss) var dismiss
    @State private var jsonString = ""
    @State private var copied = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    Text(jsonString)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.green)
                        .padding()
                }
            }
            .navigationTitle("Order JSON")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        copyToClipboard()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied" : "Copy")
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
        }
        .onAppear {
            jsonString = OrderSubmissionHelper.generateJSON(order) ?? "{}"
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = jsonString
        copied = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}

#Preview {
    SavedOrdersView()
}
