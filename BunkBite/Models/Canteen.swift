//
//  Canteen.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import Foundation

struct CanteenOwner: Codable, Hashable {
    let id: String
    let email: String
    let role: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email, role, name
    }
}

struct Canteen: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let place: String
    let ownerId: String
    let owner: CanteenOwner?
    let menu: [MenuItem]?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, place, ownerId, owner, menu, createdAt, updatedAt
    }
    
    // Custom init for decoding flexibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        place = try container.decode(String.self, forKey: .place)
        menu = try? container.decode([MenuItem]?.self, forKey: .menu)
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        updatedAt = try? container.decode(String.self, forKey: .updatedAt)
        
        // Backend can return ownerId as either:
        // 1. An object with _id, email, role (GET /canteens)
        // 2. A plain string (POST /canteens response)
        
        if let ownerObj = try? container.decode(CanteenOwner.self, forKey: .ownerId) {
            // Case 1: ownerId is an object
            owner = ownerObj
            ownerId = ownerObj.id
        } else if let ownerIdString = try? container.decode(String.self, forKey: .ownerId) {
            // Case 2: ownerId is a string
            ownerId = ownerIdString
            owner = nil
        } else if let ownerObj = try? container.decode(CanteenOwner.self, forKey: .owner) {
            // Case 3: owner field exists as object
            owner = ownerObj
            ownerId = ownerObj.id
        } else {
            // Fallback
            ownerId = try container.decode(String.self, forKey: .ownerId)
            owner = nil
        }
    }
    
    // Manual init for creating instances
    init(id: String, name: String, place: String, ownerId: String, owner: CanteenOwner? = nil, menu: [MenuItem]? = nil, createdAt: String? = nil, updatedAt: String? = nil) {
        self.id = id
        self.name = name
        self.place = place
        self.ownerId = ownerId
        self.owner = owner
        self.menu = menu
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}



struct CreateCanteenRequest: Codable {
    let name: String
    let place: String
    let ownerId: String
}
