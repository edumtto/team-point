//
//  GameData.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 11/2/25.
//

import SocketIO
import Foundation

// Data transfer model
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
    }
    
    enum State: String, Decodable {
        case lobby
        case selecting
        case finished
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let statusString = try? container.decode(String.self)
            
            switch statusString?.lowercased() {
            case "lobby": self = .lobby
            case "selecting": self = .selecting
            case "finished": self = .finished
            default: self = .lobby
            }
        }
    }
    
    let players: [Player]
    let state: State
}
