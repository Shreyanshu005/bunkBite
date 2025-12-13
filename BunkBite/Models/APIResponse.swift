//
//  APIResponse.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import Foundation

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
}

struct EmptyData: Codable {}
