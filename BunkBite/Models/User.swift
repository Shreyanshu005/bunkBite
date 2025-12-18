//
//  User.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let role: String

    var isOwner: Bool {
        return role.lowercased() == "admin"
    }
}

struct AuthResponse: Codable {
    let success: Bool
    let token: String?
}

