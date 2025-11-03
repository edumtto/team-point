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
    
    @Published var roomModel: RoomModel = .init(players: [], state: .lobby)
    @Published var showCardSelector: Bool = false
    @Published var selectedCardIndex: Int? = nil
    
    var shareableRoomNumber: String {
        "TeamPoint: Join room number \(roomNumber)."
    }
    
    init(roomNumber: String, playerId: String, playerName: String, isHost: Bool, socketService: SocketServiceProtocol) {
        self.roomNumber = roomNumber
        self.playerId = playerId
        self.playerName = playerName
        self.isHost = isHost
    
        let players = [RoomModel.Player(id: playerId, name: playerName)]
        self.roomModel = RoomModel(players: players, state: .lobby)
        
        self.socketService = socketService
        self.socketService.gameDelegate = self
    }
    
    func handleHostAction() {
        switch roomModel.state {
        case .lobby, .finished:
            startGame()
        case .selecting(_, _):
            endGame()
        }
    }
    
    private func updateStatePresentation() {
        switch roomModel.state {
        case .lobby:
            showCardSelector = false
            selectedCardIndex = nil
        case .selecting(count: _, total: _):
            showCardSelector = true
        case .finished:
            showCardSelector = false
            selectedCardIndex = nil
        }
    }
    
    func leaveRoom() {
        print("Leaving room...")
        socketService.leaveRoom(roomNumber: roomNumber, playerId: playerId)
    }
    
    private func startGame() {
        print("Starting game...")
        roomModel.state = .selecting(count: 0, total: roomModel.players.count)
        updateStatePresentation()
        socketService.startGame(roomNumber: roomNumber)
    }
    
    private func endGame() {
        print("Revealing cards...")
//        roomModel.state = .finished
        updateStatePresentation()
        socketService.endGame(roomNumber: roomNumber)
    }
    
    func selectCard(_ cardIndex: Int) {
        selectedCardIndex = selectedCardIndex == cardIndex ? nil : cardIndex
        let playerData = GameData.Player(id: playerId, name: playerName, selectedCardIndex: selectedCardIndex ?? -1)
        socketService.selectCard(roomNumber: roomNumber, player: playerData)
    };
}

extension RoomViewModel: SocketGameDelegate {
    func didFail(error: SocketError) {
        print("didFail delegate called")
    }
    
    func didUpdateGame(_ gameData: GameData) {
        print("didUpdateGame delegate called")
        roomModel = RoomModel(gameData: gameData)
        updateStatePresentation()
    }
}
