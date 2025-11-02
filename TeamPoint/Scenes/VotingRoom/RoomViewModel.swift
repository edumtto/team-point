//
//  RoomViewModel.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import Combine
import Foundation

protocol RoomProtocol {
    func startVoting()
    func vote(points: Int, playerName: String)
    func revealVotes()
    func restartVoting()
    var isHost: Bool { get }
}

@MainActor
final class RoomViewModel: ObservableObject {
    private var socketService: SocketServiceProtocol
    static let availableCards: [Int] = [0, 1, 2, 3, 5, 8, 13, 20, 40, 100]
    let roomNumber: String
    let playerName: String
    let playerId: String
    let isHost: Bool
    
    private var playerData: GameData.Player {
        .init(id: playerId, name: playerName, selectedCardIndex: selectedCardIndex ?? -1)
    }
    
    @Published var roomState: State = .waitingForParticipants
    
    @Published var players: [Player] = []
    
    @Published var selectedCardIndex: Int? = nil
    
    init(roomNumber: String, playerName: String, isHost: Bool, socketService: SocketServiceProtocol) {
        self.roomNumber = roomNumber
        self.playerName = playerName
        self.isHost = isHost
        
        self.playerId = UUID().uuidString
        self.players = [Player(id: playerId, name: playerName)]
        
        self.socketService = socketService
        self.socketService.delegate = self
        
        emitEnterRoom()
    }
    
    func selectCard(_ cardIndex: Int) {
        selectedCardIndex = selectedCardIndex == cardIndex ? nil : cardIndex
        socketService.selectCard(player: playerData)
    }
    
    private func emitEnterRoom() {
        socketService.enterRoom(player: playerData)
    }
}

extension RoomViewModel: SocketEventsDelegate {
    func didUpdateGame(_ gameData: GameData) {
        
    }
    
    func didJoinRoom() {
    }
    
    func didFail(error: SocketError) {
    
    }
    
    func didCloseConnection() {
    }
    
    func didStartGame() {
        
    }
    
    func didEndGame() {
        
    }
}

extension RoomViewModel {
    enum State {
        case waitingForParticipants
        case voting(count: Int, total: Int)
        case waitingForHost
        case revealed
        
        var description: String {
            switch self {
            case .waitingForParticipants:
                return "Waiting for participants..."
            case .voting(let count, let total):
                return "\(count) of \(total) votes received"
            case .waitingForHost:
                return "Waiting for host..."
            case .revealed:
                return "Results revealed"
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
                return availableCards[index]
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
