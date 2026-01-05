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
    
    // New Fields
    let image: String?
    let category: String?
    let isOpen: Bool
    let isCurrentlyOpen: Bool?
    let openingTime: String?
    let closingTime: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, place, ownerId, owner, menu, createdAt, updatedAt
        case image, category, isOpen, isCurrentlyOpen, openingTime, closingTime
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
        
        // Handle owner/ownerId
        if let ownerObj = try? container.decode(CanteenOwner.self, forKey: .owner) {
            owner = ownerObj
            ownerId = ownerObj.id
        } else if let ownerIdString = try? container.decode(String.self, forKey: .owner) {
            ownerId = ownerIdString
            owner = nil
        } else if let ownerIdString = try? container.decode(String.self, forKey: .ownerId) {
            ownerId = ownerIdString
            owner = nil
        } else {
            // Fallback for safety, though API should provide one
            ownerId = ""
            owner = nil
        }
        
        // Handle new fields with defaults
        image = try? container.decode(String.self, forKey: .image)
        category = try? container.decode(String.self, forKey: .category)
        isOpen = try container.decodeIfPresent(Bool.self, forKey: .isOpen) ?? true
        isCurrentlyOpen = try? container.decode(Bool.self, forKey: .isCurrentlyOpen)
        openingTime = try container.decodeIfPresent(String.self, forKey: .openingTime)
        closingTime = try container.decodeIfPresent(String.self, forKey: .closingTime)
    }
    
    // Manual init
    init(id: String, name: String, place: String, ownerId: String, owner: CanteenOwner? = nil, menu: [MenuItem]? = nil, isOpen: Bool = true, isCurrentlyOpen: Bool? = nil, openingTime: String? = nil, closingTime: String? = nil) {
        self.id = id
        self.name = name
        self.place = place
        self.ownerId = ownerId
        self.owner = owner
        self.menu = menu
        self.createdAt = nil
        self.updatedAt = nil
        self.image = nil
        self.category = nil
        self.isOpen = isOpen
        self.isCurrentlyOpen = isCurrentlyOpen
        self.openingTime = openingTime
        self.closingTime = closingTime
    }
    
    // Logic to check if canteen is currently accepting orders
    var isAcceptingOrders: (Bool, String) {
        // 1. Check Manual Switch
        if !isOpen {
            return (false, "Canteen is currently closed (Manually Closed)")
        }
        
        // 2. Use Backend-provided availability if available
        if let currentlyOpen = isCurrentlyOpen {
            if currentlyOpen {
                return (true, "Open")
            } else {
                let range = (openingTime != nil && closingTime != nil) ? ": \(openingTime!) - \(closingTime!)" : ""
                return (false, "Canteen is closed. Operating hours\(range)")
            }
        }
        
        // 3. Fallback to client-side logic (Keep as backup for older API responses)
        guard let openStr = openingTime, let closeStr = closingTime else {
            return (true, "Open")
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata") // Use IST for consistency
        
        let now = Date()
        let calendar = Calendar.current
        
        let currentComp = calendar.dateComponents(in: TimeZone(identifier: "Asia/Kolkata")!, from: now)
        let currentMinutes = (currentComp.hour ?? 0) * 60 + (currentComp.minute ?? 0)
        
        guard let openDate = formatter.date(from: openStr),
              let closeDate = formatter.date(from: closeStr) else {
            return (true, "Open")
        }
        
        let openComp = calendar.dateComponents([.hour, .minute], from: openDate)
        let closeComp = calendar.dateComponents([.hour, .minute], from: closeDate)
        
        let openMinutes = (openComp.hour ?? 0) * 60 + (openComp.minute ?? 0)
        let closeMinutes = (closeComp.hour ?? 0) * 60 + (closeComp.minute ?? 0)
        
        if currentMinutes >= openMinutes && currentMinutes < closeMinutes {
            return (true, "Open")
        } else {
            return (false, "Canteen is closed. Operating hours: \(openStr) - \(closeStr)")
        }
    }
}

struct CreateCanteenRequest: Codable {
    let name: String
    let place: String
    let ownerId: String
}
