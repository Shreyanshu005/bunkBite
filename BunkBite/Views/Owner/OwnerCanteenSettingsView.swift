import SwiftUI

struct OwnerCanteenSettingsView: View {
    @ObservedObject var canteenViewModel: CanteenViewModel
    @ObservedObject var authViewModel: AuthViewModel
    
    @State private var isOpen: Bool = true
    @State private var openingTime: Date = Date()
    @State private var closingTime: Date = Date()
    @State private var isSaving = false
    @State private var showSaveAlert = false
    @State private var saveMessage = ""
    
    // Time formatter
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Manual Control
                Section(header: Text("Live Status")) {
                    HStack {
                        Image(systemName: isOpen ? "lock.open.fill" : "lock.fill")
                            .foregroundStyle(isOpen ? .green : .red)
                        
                        Toggle(isOn: $isOpen) {
                            VStack(alignment: .leading) {
                                Text(isOpen ? "Canteen is OPEN" : "Canteen is CLOSED")
                                    .font(.headline)
                                    .foregroundStyle(isOpen ? .green : .red)
                                
                                Text(isOpen ? "Students can place orders" : "Ordering is disabled")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .onChange(of: isOpen) { oldValue, newValue in
                            // Auto-save toggle status
                            updateStatus(isOpen: newValue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                
                // Section 2: Operating Hours
                Section(header: Text("Operating Hours")) {
                    DatePicker("Opening Time", selection: $openingTime, displayedComponents: .hourAndMinute)
                    DatePicker("Closing Time", selection: $closingTime, displayedComponents: .hourAndMinute)
                    
                    Button {
                        saveTimes()
                    } label: {
                        if isSaving {
                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save Times")
                        }
                    }
                    .disabled(isSaving)
                }
                
                Section {
                    Text("Automatic operating hours will only work if the main switch above is set to OPEN.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Canteen Settings")
            .onAppear {
                loadCurrentSettings()
            }
            .alert("Settings", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveMessage)
            }
        }
    }
    
    private func loadCurrentSettings() {
        guard let canteen = canteenViewModel.selectedCanteen else { return }
        isOpen = canteen.isOpen
        
        if let openStr = canteen.openingTime, let date = timeFormatter.date(from: openStr) {
            openingTime = date
        } else {
            openingTime = timeFormatter.date(from: "09:00") ?? Date()
        }
        
        if let closeStr = canteen.closingTime, let date = timeFormatter.date(from: closeStr) {
            closingTime = date
        } else {
            closingTime = timeFormatter.date(from: "18:00") ?? Date()
        }
    }
    
    private func updateStatus(isOpen: Bool) {
        guard let canteenId = canteenViewModel.selectedCanteen?.id,
              let token = authViewModel.authToken else { return }
        
        Task {
            do {
                // Call API and capture the updated canteen object
                let updatedCanteen = try await APIService.shared.toggleCanteenStatus(canteenId: canteenId, token: token)
                
                // CRITICAL: Update the ViewModel so other views (like the Banner) react immediately
                await MainActor.run {
                    canteenViewModel.selectedCanteen = updatedCanteen
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(isOpen ? .success : .warning)
                }
            } catch {
                await MainActor.run {
                    // Revert toggle on failure
                    self.isOpen = !isOpen
                    saveMessage = "Failed to update status: \(error.localizedDescription)"
                    showSaveAlert = true
                }
            }
        }
    }
    
    private func saveTimes() {
        guard let canteenId = canteenViewModel.selectedCanteen?.id,
              let token = authViewModel.authToken else { return }
        
        isSaving = true
        
        let openStr = timeFormatter.string(from: openingTime)
        let closeStr = timeFormatter.string(from: closingTime)
        
        let data: [String: Any] = [
            "openingTime": openStr,
            "closingTime": closeStr
            // Do NOT send isOpen here, as it might conflict with the toggle
        ]
        
        Task {
            do {
                let updatedCanteen = try await APIService.shared.updateCanteen(canteenId: canteenId, data: data, token: token)
                await MainActor.run {
                    canteenViewModel.selectedCanteen = updatedCanteen
                    saveMessage = "Operating hours saved successfully!"
                    showSaveAlert = true
                }
            } catch {
                await MainActor.run {
                    saveMessage = "Failed to save settings: \(error.localizedDescription)"
                    showSaveAlert = true
                }
            }
            await MainActor.run {
                isSaving = false
            }
        }
    }
}
