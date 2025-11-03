//
//  SocketError.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 11/2/25.
//

import Foundation

enum SocketError: LocalizedError, Identifiable {
    case notConnected
    case notJoined
    
    // Provide a stable identifier per case so it can be used with `.alert(item:)`
    var id: String {
        switch self {
        case .notConnected:
            return "notConnected"
        case .notJoined:
            return "notJoined"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Error connecting. Check your internet connection."
        case .notJoined:
            return "Error joining the game. Try again later."
        }
    }
}
