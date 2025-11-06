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
    @Published var selectedCanteen: Canteen?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchAllCanteens(token: String) async {
        isLoading = true
        errorMessage = nil

        print("🔄 Fetching all canteens with token: \(token.prefix(20))...")

        do {
            canteens = try await apiService.getAllCanteens(token: token)
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
            errorMessage = "Failed to fetch your canteens"
        }

        isLoading = false
    }

    func createCanteen(name: String, place: String, ownerId: String, token: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let canteen = try await apiService.createCanteen(name: name, place: place, ownerId: ownerId, token: token)
            canteens.append(canteen)
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to create canteen"
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
