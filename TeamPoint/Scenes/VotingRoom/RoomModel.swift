//
//  RoomModel.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 11/2/25.
//

enum RoomModel {
    enum State: Equatable {
        case waitingForParticipants
        case voting(count: Int, total: Int)
        case revealed
        
        var description: String {
            switch self {
            case .waitingForParticipants:
                return "Waiting for participants..."
            case .voting(let count, let total):
                return "\(count) of \(total) votes received"
            case .revealed:
                return "Results revealed"
            }
        }
        
        var hostButtonTitle: String {
            switch self {
            case .waitingForParticipants:
                return "Start Game"
            case .voting:
                return "Reveal Cards"
            case .revealed:
                return "New Round"
            }
        }
            
        var hostButtonIcon: String {
            switch self {
            case .waitingForParticipants:
                return "play.fill"
            case .voting:
                return "eye.fill"
            case .revealed:
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
    }
}
