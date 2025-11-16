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
    let message: String
    let token: String?
    let user: User?
}

struct SendOTPResponse: Codable {
    let success: Bool
    let message: String
}
