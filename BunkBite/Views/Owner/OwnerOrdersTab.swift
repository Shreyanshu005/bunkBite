//
//  OwnerOrdersTab.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct OwnerOrdersTab: View {
    let canteen: Canteen?
    @ObservedObject var authViewModel: AuthViewModel
    let onSelectCanteen: () -> Void

    var body: some View {
        NavigationStack {
            if let selectedCanteen = canteen {
                ordersView(for: selectedCanteen)
            } else {
                noCanteenView
            }
        }
    }

    private var noCanteenView: some View {
        List {
            ContentUnavailableView {
                Label("No Canteen Selected", systemImage: "building.2")
            } description: {
                Text("Select a canteen to view orders")
            } actions: {
                Button("Select Canteen") {
                    onSelectCanteen()
                }
                .buttonStyle(.borderedProminent)
                .tint(Constants.primaryColor)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Orders")
    }

    private func ordersView(for selectedCanteen: Canteen) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedCanteen.name)
                        .font(.title3)
                        .fontWeight(.bold)

                    Label(selectedCanteen.place, systemImage: "mappin.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )

            ContentUnavailableView("No orders yet", systemImage: "list.clipboard")
                .listRowBackground(Color.clear)
        }
        .navigationTitle("Orders")
    }
}
