//
//  GameData.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 11/2/25.
//

import SocketIO
import Foundation

struct GameData: Decodable {
    struct Player: Identifiable, Codable, SocketData {
        let id: String
        let name: String
        let selectedCardIndex: Int // -1 represents no card selected
        
        init(id: String, name: String, selectedCardIndex: Int = -1) {
            self.id = id
            self.name = name
            self.selectedCardIndex = selectedCardIndex
        }
        
        func jsonData() -> [String: Any]? {
            do {
               let jsonData = try JSONEncoder().encode(self)
                return try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
           } catch {
               print("Error encoding struct: \(error)")
               return nil
           }
        }
    
    }
    
    enum State: Decodable {
        case waiting
        case started
        case ended
    }
    
    let players: [Player]
    let state: State
}
