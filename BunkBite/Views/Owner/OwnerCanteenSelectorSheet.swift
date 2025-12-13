//
//  OwnerCanteenSelectorSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct OwnerCanteenSelectorSheet: View {
    @ObservedObject var canteenViewModel: CanteenViewModel
    @ObservedObject var authViewModel: AuthViewModel

    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var showCreateCanteen = false
    @State private var canteenToDelete: Canteen?
    @State private var showDeleteConfirmation = false
    @State private var deleteConfirmationEmail = ""
    @State private var isDeleting = false
    @State private var deleteError: String?

    var filteredCanteens: [Canteen] {
        if searchText.isEmpty {
            return canteenViewModel.canteens
        }
        return canteenViewModel.canteens.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.place.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if canteenViewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if canteenViewModel.canteens.isEmpty {
                    ContentUnavailableView {
                        Label("No Canteens", systemImage: "building.2")
                    } description: {
                        Text("Create your first canteen to get started")
                    } actions: {
                        Button("Create Canteen") {
                            showCreateCanteen = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Constants.primaryColor)
                    }
                    .listRowBackground(Color.clear)
                }
                
                ForEach(filteredCanteens) { canteen in
                    Button {
                        canteenViewModel.selectedCanteen = canteen
                        dismiss()
                    } label: {
                        HStack(spacing: 16) {
                            // Icon
                            Circle()
                                .fill(Constants.primaryColor.opacity(0.1))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "building.2.fill")
                                        .foregroundStyle(Constants.primaryColor)
                                        .font(.title3)
                                )

                            // Details
                            VStack(alignment: .leading, spacing: 4) {
                                Text(canteen.name)
                                    .font(.headline)
                                    .foregroundStyle(.black)

                                Label(canteen.place, systemImage: "mappin.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                            }

                            Spacer()

                            if canteenViewModel.selectedCanteen?.id == canteen.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Constants.primaryColor)
                                    .font(.title2)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 4)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            canteenToDelete = canteen
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Select Canteen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateCanteen = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search canteens")
            .refreshable {
                if let token = authViewModel.authToken {
                    await canteenViewModel.fetchMyCanteens(token: token)
                }
            }
            .sheet(isPresented: $showCreateCanteen) {
                CreateCanteenSheet(
                    canteenViewModel: canteenViewModel,
                    authViewModel: authViewModel
                )
            }
            .sheet(isPresented: $showDeleteConfirmation) {
                DeleteCanteenConfirmationSheet(
                    canteen: canteenToDelete,
                    userEmail: authViewModel.currentUser?.email ?? "",
                    confirmationEmail: $deleteConfirmationEmail,
                    isDeleting: $isDeleting,
                    errorMessage: $deleteError,
                    onConfirm: {
                        Task {
                            await performDeletion()
                        }
                    }
                )
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(canteenViewModel.selectedCanteen == nil)
        .task {
            if let token = authViewModel.authToken {
                await canteenViewModel.fetchMyCanteens(token: token)
            }
        }
    }
    
    private func performDeletion() async {
        guard let canteen = canteenToDelete,
              let token = authViewModel.authToken,
              let userEmail = authViewModel.currentUser?.email else {
            deleteError = "Missing required information"
            return
        }
        
        // Verify email matches
        guard deleteConfirmationEmail.lowercased() == userEmail.lowercased() else {
            deleteError = "Email does not match your account email"
            return
        }
        
        isDeleting = true
        deleteError = nil
        
        let success = await canteenViewModel.deleteCanteen(id: canteen.id, token: token)
        
        isDeleting = false
        
        if success {
            showDeleteConfirmation = false
            deleteConfirmationEmail = ""
            canteenToDelete = nil
        } else {
            deleteError = "Failed to delete canteen. Please try again."
        }
    }
}

struct DeleteCanteenConfirmationSheet: View {
    let canteen: Canteen?
    let userEmail: String
    @Binding var confirmationEmail: String
    @Binding var isDeleting: Bool
    @Binding var errorMessage: String?
    let onConfirm: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @FocusState private var isEmailFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Warning Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
                    .padding(.top, 20)
                
                // Warning Text
                VStack(spacing: 8) {
                    Text("Delete Canteen?")
                        .font(.urbanist(size: 24, weight: .bold))
                    
                    if let canteen = canteen {
                        Text("You are about to delete \"\(canteen.name)\"")
                            .font(.urbanist(size: 16, weight: .regular))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("This action cannot be undone.")
                        .font(.urbanist(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                }
                
                // Email Verification
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type your email to confirm:")
                        .font(.urbanist(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    TextField("Email", text: $confirmationEmail)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .focused($isEmailFieldFocused)
                    
                    Text("Your email: \(userEmail)")
                        .font(.urbanist(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.urbanist(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button {
                        onConfirm()
                    } label: {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Delete")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .frame(maxWidth: .infinity)
                    .disabled(confirmationEmail.isEmpty || isDeleting)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Focus the text field when sheet appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isEmailFieldFocused = true
                }
            }
        }
    }
}
