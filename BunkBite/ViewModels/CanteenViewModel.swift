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

        do {
            try await apiService.deleteCanteen(id: id, token: token)
            canteens.removeAll { $0.id == id }
            if selectedCanteen?.id == id {
                selectedCanteen = nil
            }
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to delete canteen"
            isLoading = false
            return false
        }
    }
}
