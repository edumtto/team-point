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
    
    var id: String {
        self.rawValue
    }
    
    var errorDescription: String? {
        "Error connecting. Check your internet connection."
    }
}
