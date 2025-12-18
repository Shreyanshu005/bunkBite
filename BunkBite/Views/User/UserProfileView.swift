//
//  UserProfileView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct UserProfileView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject var cart: Cart
    @EnvironmentObject var canteenViewModel: CanteenViewModel
    @Binding var showLoginSheet: Bool
    @State private var showContent = false
    @State private var showLogoutAlert = false
    @State private var showDeleteConfirmation = false
    @State private var showCart = false

    var body: some View {
        NavigationStack {
            ZStack {
                Constants.backgroundColor.ignoresSafeArea()

                if viewModel.isAuthenticated {
                    profileContent
                } else {
                    loginPrompt
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CartToolbarButton(
                        authViewModel: viewModel,
                        showCart: $showCart,
                        showLoginSheet: $showLoginSheet
                    )
                }
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    withAnimation {
                        viewModel.logout()
                    }
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .sheet(isPresented: $showCart) {
                CartSheet(cart: cart, authViewModel: viewModel, canteen: canteenViewModel.selectedCanteen)
            }
            .onAppear {
                withAnimation(Constants.bouncyAnimation.delay(0.1)) {
                    showContent = true
                }
            }
        }
    }
    
    private var loginPrompt: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(Constants.primaryColor.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showContent ? 1 : 0.8)

                    Image(systemName: "person.circle")
                        .font(.urbanist(size: 50, weight: .light))
                        .foregroundStyle(Constants.primaryColor)
                        .scaleEffect(showContent ? 1 : 0.5)
                }

                // Message
                VStack(spacing: 12) {
                    Text("Profile")
                        .font(.urbanist(size: 28, weight: .bold))
                        .foregroundStyle(.black)

                    Text("Login to access your profile")
                        .font(.urbanist(size: 16, weight: .regular))
                        .foregroundStyle(.gray)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // CTA Button
                Button {
                    showLoginSheet = true
                } label: {
                    Text("Login")
                        .font(.urbanist(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 200)
                        .padding(.vertical, 16)
                        .background(Constants.primaryColor)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.backgroundColor)
    }

    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Profile Header
                VStack(spacing: 20) {
                    // Avatar (Generic)
                    Circle()
                        .fill(Constants.primaryColor.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Constants.primaryColor)
                        )
                        .scaleEffect(showContent ? 1 : 0.5)
                        .opacity(showContent ? 1 : 0)

                    // User Info (Email Only)
                    VStack(spacing: 8) {
                        Text(viewModel.currentUser?.email ?? "")
                            .font(.urbanist(size: 20, weight: .bold)) // Increased size for emphasis
                            .foregroundColor(.black)
                    }
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)
                }
                .padding(.top, 60)

                // User Details Card
                VStack(spacing: 0) {
                    ProfileDetailRow(
                        icon: "person.fill",
                        label: "Name",
                        value: viewModel.currentUser?.name ?? "N/A"
                    )

                    Divider()
                        .padding(.leading, 56)

                    ProfileDetailRow(
                        icon: "envelope.fill",
                        label: "Email",
                        value: viewModel.currentUser?.email ?? "N/A"
                    )
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                .padding(.horizontal, 24)
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)

                // Logout Button
                Button(action: {
                    showLogoutAlert = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 20))
                        Text("Logout")
                            .font(.urbanist(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Constants.primaryColor)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)

                // Delete Account Button (Danger Zone)
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Text("Delete Account")
                        .font(.urbanist(size: 15, weight: .medium))
                        .foregroundStyle(.red)
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
                .offset(y: showContent ? 0 : 30)
                .opacity(showContent ? 1 : 0)

                Spacer(minLength: 60)
            }
        }
        .sheet(isPresented: $showDeleteConfirmation) {
            DeleteAccountSheet(viewModel: viewModel)
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
        }
    }
}

struct ProfileDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(Constants.primaryColor.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(Constants.primaryColor)
                )

            // Label & Value
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.urbanist(size: 13, weight: .medium))
                    .foregroundColor(.gray)

                Text(value)
                    .font(.urbanist(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

struct DeleteAccountSheet: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var confirmationText = ""
    @State private var isDeleting = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Warning Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.red)
                    .padding(.top, 20)
                
                // Warning Text
                VStack(spacing: 8) {
                    Text("Delete Account?")
                        .font(.urbanist(size: 22, weight: .bold))
                    
                    Text("This action is irreversible. All your pending orders and managed canteens (if any) will be deleted/closed.")
                        .font(.urbanist(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .fixedSize(horizontal: false, vertical: true) // Force wrapping
                }
                
                // Confirmation Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type 'delete' to confirm:")
                        .font(.urbanist(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    TextField("delete", text: $confirmationText)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 30)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.urbanist(size: 13, weight: .medium))
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
                        isDeleting = true
                        Task {
                            let success = await viewModel.deleteAccount()
                            if success {
                                dismiss()
                            }
                            isDeleting = false
                        }
                    } label: {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Delete Forever")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .frame(maxWidth: .infinity)
                    .disabled(confirmationText != "delete" || isDeleting)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
