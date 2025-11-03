//
//  RoomModel.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 11/2/25.
//

import Foundation

// Presentation model
@MainActor
final class RoomModel {
    enum State: Equatable {
        case lobby
        case selecting(count: Int, total: Int)
        case finished(averageScore: Double)
        
        var description: String {
            switch self {
            case .lobby:
                return "Waiting for participants..."
            case .selecting(let count, let total):
                return "\(count) of \(total) votes received"
            case .finished(let averageScore):
                return String(format: "%.2f", averageScore) + " is the average score"
            }
        }
        
        var hostButtonTitle: String {
            switch self {
            case .lobby:
                return "Start Game"
            case .selecting:
                return "Reveal Cards"
            case .finished:
                return "New Round"
            }
        }
        
        var hostButtonIcon: String {
            switch self {
            case .lobby:
                return "play.fill"
            case .selecting:
                return "eye.fill"
            case .finished:
                return "arrow.clockwise"
            }
        }
    }
    
    struct Player: Identifiable {
        let id: String
        let name: String
        var selectedCardIndex: Int?
        
        var hasVoted: Bool {
            selectedCardIndex != nil
        }
        
        var cardValue: Int? {
            if let index = selectedCardIndex {
                return GlobalConstants.availableCards[index]
            }
            return nil
        }
        
        init(id: String, name: String, selectedCardIndex: Int? = nil) {
            self.id = id
            self.name = name
            self.selectedCardIndex = selectedCardIndex
        }
        
        init (_ player: GameData.Player) {
            self.id = player.id
            self.name = player.name
            self.selectedCardIndex = player.selectedCardIndex == -1 ? nil : player.selectedCardIndex
        }
    }
    
    var players: [Player]
    var state: State
    
    var averageScore: Double {
        let sum = players.reduce(0, { $0 + ($1.cardValue ?? 0) })
        return Double(sum) / Double(players.count)
    }
    
    init(players: [Player], state: State) {
        self.players = players
        self.state = state
    }
    
    init(gameData: GameData) {
        let mappedPlayers = gameData.players.map(Player.init).sorted { $0.name < $1.name }
        self.players = mappedPlayers
        
        switch gameData.state {
        case .lobby:
            self.state = .lobby
        case .finished:
            let pointsSum = mappedPlayers.reduce(0, { $0 + ($1.cardValue ?? 0) })
            let averageValue = Double(pointsSum) / Double(mappedPlayers.count)
            self.state = .finished(averageScore: averageValue)
        case .selecting:
            let totalPlayers = mappedPlayers.count
            let playersWhoSelected = mappedPlayers.filter { $0.selectedCardIndex != nil }.count
            self.state = .selecting(count: playersWhoSelected, total: totalPlayers)
        }
    }
}
