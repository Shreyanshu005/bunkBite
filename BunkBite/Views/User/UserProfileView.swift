//
//  UserProfileView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct UserProfileView: View {
    @ObservedObject var viewModel: AuthViewModel
    @ObservedObject var orderViewModel: OrderViewModel
    @Binding var showLoginSheet: Bool
    
    // Environment
    @EnvironmentObject var cart: Cart
    @EnvironmentObject var canteenViewModel: CanteenViewModel

    // State
    @State private var showOrdersSheet = false
    @State private var showDeleteAlert = false
    @State private var showLogoutAlert = false // Not used per se, direct action in new design or alert
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if viewModel.isAuthenticated {
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Profile")
                                    .font(.custom("Urbanist-Bold", size: 28))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 20)
                                
                                Rectangle()
                                    .fill(Color(hex: "E5E7EB"))
                                    .frame(height: 1.0)
                                    .padding(.horizontal, -20)
                                    .padding(.top, 4)
                            }
                            .background(Color.white)
                            
                            // User Info Card
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color(hex: "E0FDE8")) // Very light green
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "person")
                                            .font(.system(size: 32, weight: .medium))
                                            .foregroundStyle(Color(hex: "22C55E")) // Green icon
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.currentUser?.email.split(separator: "@").first?.capitalized ?? "User")
                                        .font(.custom("Urbanist-Bold", size: 20))
                                        .foregroundStyle(.black)
                                    
                                    Text(viewModel.currentUser?.email ?? "user@example.com")
                                        .font(.custom("Urbanist-Medium", size: 14))
                                        .foregroundStyle(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
                            )
                            
                            // Menu Group 1
                            VStack(spacing: 0) {
                                NavigationLink(destination: MyOrdersView(orderViewModel: orderViewModel).navigationBarBackButtonHidden(false)) {
                                    ProfileOptionRow(icon: "cube.box", text: "My Orders")
                                }
                                
                                Rectangle()
                                    .fill(Color(hex: "E5E7EB"))
                                    .frame(height: 1.0)
                                    .padding(.leading, 56)
                                
                                Button {
                                    if let url = URL(string: "mailto:bunkbite58@gmail.com") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ProfileOptionRow(icon: "questionmark.circle", text: "Help & Support")
                                        
                                        Text("bunkbite58@gmail.com")
                                            .font(.custom("Urbanist-Medium", size: 12))
                                            .foregroundStyle(.gray)
                                            .padding(.leading, 56)
                                            .padding(.bottom, 12)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
                            )
                            
                            // Menu Group 2 (Danger Zone)
                            VStack(spacing: 0) {
                                Button {
                                    showDeleteAlert = true
                                } label: {
                                    HStack(spacing: 16) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.red)
                                        
                                        Text("Delete Account")
                                            .font(.custom("Urbanist-Medium", size: 16))
                                            .foregroundStyle(.red)
                                        
                                        Spacer()
                                    }
                                    .padding(20)
                                }
                                
                                Rectangle()
                                    .fill(Color(hex: "E5E7EB"))
                                    .frame(height: 1.0)
                                    .padding(.leading, 56)
                                
                                Button {
                                    showLogoutAlert = true
                                } label: {
                                    HStack(spacing: 16) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.red)
                                        
                                        Text("Logout")
                                            .font(.custom("Urbanist-Medium", size: 16))
                                            .foregroundStyle(.red)
                                        
                                        Spacer()
                                    }
                                    .padding(20)
                                }
                                .alert("Logout", isPresented: $showLogoutAlert) {
                                    Button("Cancel", role: .cancel) { }
                                    Button("Logout", role: .destructive) {
                                        viewModel.logout()
                                    }
                                } message: {
                                    Text("Are you sure you want to log out?")
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "E5E7EB"), lineWidth: 1.0)
                            )
                            
                            Spacer()
                        }
                        .padding(20)
                    }

                } else {
                     // Login Prompt
                     VStack(spacing: 20) {
                         VStack(alignment: .leading, spacing: 12) {
                             Text("Profile")
                                 .font(.custom("Urbanist-Bold", size: 28))
                                 .foregroundStyle(.black)
                                 .padding(.horizontal, 20)
                                 .padding(.top, 20)
                             
                             Rectangle()
                                 .fill(Color(hex: "E5E7EB"))
                                 .frame(height: 1.0)
                                 .padding(.horizontal, -20)
                                 .padding(.top, 4)
                         }
                         .background(Color.white)
                         
                         Spacer()
                         Image(systemName: "person.circle")
                             .font(.system(size: 80))
                             .foregroundStyle(.gray)
                         
                         Text("Guest User")
                             .font(.custom("Urbanist-Bold", size: 24))
                         
                         Text("Please log in to view your profile")
                             .font(.custom("Urbanist-Medium", size: 16))
                             .foregroundStyle(.gray)
                         
                         Button {
                             showLoginSheet = true
                         } label: {
                             Text("Login / Sign Up")
                                 .font(.custom("Urbanist-Bold", size: 16))
                                 .foregroundStyle(.white)
                                 .padding(.vertical, 16)
                                 .padding(.horizontal, 40)
                                 .background(Color.black)
                                 .cornerRadius(12)
                         }
                         Spacer()
                     }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showDeleteAlert) {
                DeleteAccountSheet(viewModel: viewModel)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(30)
                    .background(Color.white.opacity(0.8))
                    .background(.ultraThinMaterial)
            }
        }
    }
}

// Helper Row
struct ProfileOptionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.black) // Standard color
            
            Text(text)
                .font(.custom("Urbanist-Medium", size: 16))
                .foregroundStyle(.black)
            
            Spacer()
            
            Image(systemName: "arrow.right")
                .font(.system(size: 16))
                .foregroundStyle(.gray)
        }
        .padding(20)
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
        VStack(spacing: 24) {
            // Detached Header
            
            // Warning Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)
                .padding(.top, 10)
            
            // Warning Text
            VStack(spacing: 8) {
                Text("Delete Account?")
                    .font(.custom("Urbanist-Bold", size: 24))
                
                Text("This action is irreversible. All your pending orders and data will be permanently deleted.")
                    .font(.custom("Urbanist-Medium", size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            // Confirmation Input
            VStack(alignment: .leading, spacing: 10) {
                Text("Type 'delete' to confirm:")
                    .font(.custom("Urbanist-Bold", size: 14))
                    .foregroundStyle(.gray)
                
                TextField("Type 'delete' here", text: $confirmationText)
                    .font(.custom("Urbanist-Medium", size: 16))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Action Button
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
                HStack {
                    if isDeleting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "trash.fill")
                        Text("Delete Permanently")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(confirmationText == "delete" ? Color.red : Color.gray.opacity(0.3))
                .foregroundStyle(.white)
                .font(.custom("Urbanist-Bold", size: 16))
                .cornerRadius(16)
            }
            .disabled(confirmationText != "delete" || isDeleting)
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .background(Color.white.opacity(0.5))
        .background(.ultraThinMaterial)
    }
}
