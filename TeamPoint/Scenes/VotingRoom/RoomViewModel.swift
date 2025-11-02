//
//  RoomViewModel.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import Combine

protocol RoomProtocol {
    func startVoting()
    func vote(points: Int, username: String)
    func revealVotes()
    func restartVoting()
    var isHost: Bool { get }
}

enum RoomState {
    case waitingParticipants
    case voting
    case revealingVotes
}

@MainActor
class RoomViewModel: ObservableObject {
    @Published var roomNumber: String
    @Published var gameState: GameState = .voting(count: 2, total: 5)
    @Published var players: [Player] = [
        Player(name: "Alice", selectedCard: 5),
        Player(name: "Bob", selectedCard: 8),
        Player(name: "Charlie", selectedCard: nil),
        Player(name: "Diana", selectedCard: 13),
        Player(name: "Eve", selectedCard: nil)
    ]
    @Published var selectedCard: Int? = nil
    
    let availableCards: [Int] = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89]
    
    init(roomNumber: String) {
        self.roomNumber = roomNumber
    }
    
    func selectCard(_ card: Int) {
        if selectedCard == card {
            selectedCard = nil
        } else {
            selectedCard = card
        }
    }
    
    func submitVote() {
        guard let card = selectedCard else { return }
        print("Submitting vote: \(card)")
        // Here you would send the vote to your backend
    }
}
