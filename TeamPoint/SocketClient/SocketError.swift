//
//  SocketError.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 11/2/25.
//

import Foundation

enum SocketError: String, LocalizedError, Identifiable {
    case connectionFailed
    case emittingFailed
    case roomNotFound
    
    var id: String {
        self.rawValue
    }
    
    var errorDescription: String? {
        switch self {
        case .roomNotFound:
            "Invalid room number."
        default:
            "Error connecting. Check your internet connection."
        }
    }
}
