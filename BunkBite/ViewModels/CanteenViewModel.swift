//
//  CanteenViewModel.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class CanteenViewModel: ObservableObject {
    @Published var canteens: [Canteen] = []
    @Published var selectedCanteen: Canteen? {
        didSet {
            saveSelectedCanteen()
            // Notify observers that the selected canteen has changed
            if let canteen = selectedCanteen {
                NotificationCenter.default.post(name: .canteenDidChange, object: nil, userInfo: ["canteen": canteen])
            }
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    init() {
        loadSelectedCanteen()
    }

    private func saveSelectedCanteen() {
        if let canteen = selectedCanteen,
           let encoded = try? JSONEncoder().encode(canteen) {
            UserDefaults.standard.set(encoded, forKey: "selectedCanteen")
            print("💾 Saved selected canteen: \(canteen.name)")
        } else {
            UserDefaults.standard.removeObject(forKey: "selectedCanteen")
            print("🗑️ Cleared selected canteen")
        }
    }

    private func loadSelectedCanteen() {
        if let data = UserDefaults.standard.data(forKey: "selectedCanteen"),
           let canteen = try? JSONDecoder().decode(Canteen.self, from: data) {
            selectedCanteen = canteen
            print("✅ Loaded selected canteen: \(canteen.name)")
        }
    }

    func clearSelectedCanteen() {
        selectedCanteen = nil
    }

    func fetchAllCanteens() async {
        isLoading = true
        errorMessage = nil

        print("🔄 Fetching all canteens (public endpoint)")

        do {
            canteens = try await apiService.getAllCanteens()
            print("✅ Fetched \(canteens.count) canteens")
            for canteen in canteens {
                print("   - \(canteen.name) at \(canteen.place)")
            }
            
            // Auto-select the first canteen if none is selected
            // or if the previously selected canteen no longer exists
            // 1. Try to restore the ongoing selection with fresh data
            if let currentSelected = selectedCanteen,
               let freshCanteen = canteens.first(where: { $0.id == currentSelected.id }) {
                selectedCanteen = freshCanteen
                print("🔄 Refreshed selected canteen with latest status: \(freshCanteen.name)")
            } 
            // 2. If no selection or previous selection is gone, auto-select first
            else {
                if let firstCanteen = canteens.first {
                    selectedCanteen = firstCanteen
                    print("📌 Auto-selected canteen: \(firstCanteen.name)")
                }
            }
        } catch {
            errorMessage = "Failed to fetch canteens"
            print("❌ Error fetching canteens: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func fetchMyCanteens(token: String) async {
        isLoading = true
        errorMessage = nil

        do {
            canteens = try await apiService.getMyCanteens(token: token)
        } catch {
            print("❌ ViewModel Error fetching canteens: \(error.localizedDescription)")
            errorMessage = "Failed to fetch your canteens"
        }

        isLoading = false
    }

    func createCanteen(name: String, place: String, ownerId: String, token: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        print("🛠️ ViewModel: Creating canteen...")
        print("Name: \(name), Place: \(place), Owner: \(ownerId)")

        do {
            let canteen = try await apiService.createCanteen(name: name, place: place, ownerId: ownerId, token: token)
            canteens.append(canteen)
            print("✅ ViewModel: Canteen appended to list")
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to create canteen. Check logs."
            print("❌ ViewModel Error: \(error)")
            isLoading = false
            return false
        }
    }

    func updateCanteen(id: String, name: String, place: String, ownerId: String, token: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let updatedCanteen = try await apiService.updateCanteen(id: id, name: name, place: place, ownerId: ownerId, token: token)
            if let index = canteens.firstIndex(where: { $0.id == id }) {
                canteens[index] = updatedCanteen
            }
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update canteen"
            isLoading = false
            return false
        }
    }

    func deleteCanteen(id: String, token: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        print("🗑️ Attempting to delete canteen with ID: \(id)")
        
        do {
            try await apiService.deleteCanteen(id: id, token: token)
            canteens.removeAll { $0.id == id }
            if selectedCanteen?.id == id {
                selectedCanteen = nil
            }
            print("✅ Successfully deleted canteen")
            isLoading = false
            return true
        } catch {
            let errorMsg = "Failed to delete canteen: \(error.localizedDescription)"
            errorMessage = errorMsg
            print("❌ \(errorMsg)")
            isLoading = false
            return false
        }
    }

    func refreshSelectedCanteen() async {
        guard let currentId = selectedCanteen?.id else { return }
        // Don't set global isLoading to avoid full screen spinner on pull-to-refresh
        do {
            // Using getAllCanteens (public) to ensure we get status even without token
            let allCanteens = try await apiService.getAllCanteens()
            if let updated = allCanteens.first(where: { $0.id == currentId }) {
                selectedCanteen = updated
                print("✅ Refreshed selected canteen status: \(updated.isAcceptingOrders.0 ? "Open" : "Closed")")
            }
        } catch {
            print("❌ Failed to refresh selected canteen: \(error.localizedDescription)")
        }
    }
    
    func fetchSelectedCanteenDetails(token: String) async {
        guard let currentId = selectedCanteen?.id else { return }
        isLoading = true
        
        do {
            let updatedCanteen = try await apiService.getCanteenById(id: currentId, token: token)
            selectedCanteen = updatedCanteen
            print("✅ Fetched fresh details for canteen: \(updatedCanteen.name)")
        } catch {
            print("❌ Failed to fetch canteen details: \(error.localizedDescription)")
            errorMessage = "Failed to refresh canteen details"
        }
        
        isLoading = false
    }
}
