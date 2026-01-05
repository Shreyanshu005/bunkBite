//
//  ScannedOrderSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 12/12/25.
//

import SwiftUI

struct ScannedOrderSheet: View {
    let order: Order
    let qrData: String
    let token: String
    @ObservedObject var viewModel: ScannerViewModel
    @Binding var isPresented: Bool
    let onPickupComplete: (() -> Void)?
    
    init(order: Order, qrData: String, token: String, viewModel: ScannerViewModel, isPresented: Binding<Bool>, onPickupComplete: (() -> Void)? = nil) {
        self.order = order
        self.qrData = qrData
        self.token = token
        self.viewModel = viewModel
        self._isPresented = isPresented
        self.onPickupComplete = onPickupComplete
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                
                Text("Order Details")
                    .font(.urbanist(size: 20, weight: .bold))
                    .padding(.vertical, 8)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Status Badge
                    HStack {
                        Spacer()
                        StatusBadge(status: order.status)
                        Spacer()
                    }
                    
                    // Order Info
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(icon: "number", title: "Order ID", value: order.orderId)
                        InfoRow(icon: "indianrupeesign", title: "Amount", value: "₹\(Int(order.totalAmount))")
                        InfoRow(icon: "clock", title: "Time", value: formatDate(order.createdAt))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Items List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Items")
                            .font(.headline)
                        
                        ForEach(order.items) { item in
                            HStack {
                                Text("\(item.quantity)x")
                                    .font(.headline)
                                    .foregroundStyle(Constants.primaryColor)
                                
                                Text(item.name)
                                    .font(.body)
                                
                                Spacer()
                                
                                Text("₹\(Int(item.price) * item.quantity)")
                                    .font(.headline)
                            }
                            Divider()
                        }
                    }
                }
                .padding()
            }
            
            // Action Button
            Button {
                Task {
                    await viewModel.completePickup(qrData: qrData, token: token)
                    if viewModel.showPickupSuccess {
                        onPickupComplete?()
                        isPresented = false
                        viewModel.resetScan()
                    }
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark as Picked Up")
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(order.status == .completed ? Color.gray : Constants.primaryColor)
                .cornerRadius(12)
            }
            .disabled(order.status == .completed || viewModel.isLoading)
            .padding()
        }
        .presentationDetents([.medium, .large])
        .alert("Pickup Successful!", isPresented: $viewModel.showPickupSuccess) {
            Button("OK") {
                onPickupComplete?()
                isPresented = false
                viewModel.resetScan()
            }
        } message: {
            Text("Order #\(order.orderId) has been marked as picked up and completed.")
        }
        .alert("Already Picked Up", isPresented: $viewModel.showAlreadyPickedUp) {
            Button("OK") {
                isPresented = false
                viewModel.resetScan()
            }
        } message: {
            Text(viewModel.alreadyPickedUpMessage)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.scanError != nil },
            set: { if !$0 { viewModel.scanError = nil } }
        )) {
            Button("OK") {
                viewModel.scanError = nil
            }
        } message: {
            Text(viewModel.scanError ?? "An error occurred")
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        return DateFormatter.formatOrderDate(dateString)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.gray)
                .frame(width: 24)
            
            Text(title)
                .foregroundStyle(.gray)
            
            Spacer()
            
            Text(value)
                .font(.headline)
        }
    }
}


