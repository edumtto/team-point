//
//  SocketError.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 11/2/25.
//

import Foundation

enum SocketError: LocalizedError, Identifiable {
    case notConnected
    
    // Provide a stable identifier per case so it can be used with `.alert(item:)`
    var id: String {
        switch self {
        case .notConnected:
            return "notConnected"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Error connecting. Check your internet connection."
        }
    }
}
