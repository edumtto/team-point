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
    let roomNumber: String
    let playerName: String
    let playerId: String
    let isHost: Bool
    
    private var playerData: GameData.Player {
        .init(id: playerId, name: playerName, selectedCardIndex: selectedCardIndex ?? -1)
    }
    
    @Published var roomState: RoomModel.State = .lobby
    @Published var showCardSelector: Bool = false
    
    @Published var players: [RoomModel.Player] = []
    
    @Published var selectedCardIndex: Int? = nil
    
    init(roomNumber: String, playerName: String, isHost: Bool, socketService: SocketServiceProtocol) {
        self.roomNumber = roomNumber
        self.playerName = playerName
        self.isHost = isHost
        
        self.playerId = UUID().uuidString
        self.players = [RoomModel.Player(id: playerId, name: playerName)]
        
        self.socketService = socketService
        self.socketService.gameDelegate = self
    }
    
    func handleHostAction() {
        switch roomState {
        case .lobby, .finished:
            startGame()
            showCardSelector = true
        case .selecting(_, _):
            endGame()
            showCardSelector = false
        }
    }
    
    private func startGame() {
        print("Starting game...")
        roomState = .selecting(count: 0, total: players.count)
        socketService.startGame()
    }
    
    private func endGame() {
        print("Revealing cards...")
        roomState = .finished
        socketService.endGame()
    }
    
    func selectCard(_ cardIndex: Int) {
        selectedCardIndex = selectedCardIndex == cardIndex ? nil : cardIndex
        socketService.selectCard(player: playerData)
    }
}

extension RoomViewModel: SocketGameDelegate {
    func didFail(error: SocketError) {
        print("didFail delegate called")
    }
    
    func didUpdateGame(_ gameData: GameData) {
        print("didUpdateGame delegate called")
        print(gameData)
    }
}

