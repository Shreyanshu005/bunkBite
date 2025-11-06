//
//  CreateCanteenSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct CreateCanteenSheet: View {
    @ObservedObject var canteenViewModel: CanteenViewModel
    @ObservedObject var authViewModel: AuthViewModel

    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var place = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Canteen Name", text: $name)
                    TextField("Location", text: $place)
                } header: {
                    Text("Canteen Details")
                } footer: {
                    if let error = canteenViewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task {
                            if let ownerId = authViewModel.currentUser?.id,
                               let token = authViewModel.authToken {
                                let success = await canteenViewModel.createCanteen(
                                    name: name,
                                    place: place,
                                    ownerId: ownerId,
                                    token: token
                                )
                                if success {
                                    dismiss()
                                }
                            }
                        }
                    } label: {
                        if canteenViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Canteen")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(name.isEmpty || place.isEmpty || canteenViewModel.isLoading)
                }
            }
            .navigationTitle("New Canteen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
