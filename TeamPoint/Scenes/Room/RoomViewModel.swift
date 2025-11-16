//
//  RoomViewModel.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import Combine
import Foundation
import OSLog

protocol RoomViewModelProtocol: ObservableObject {
    var roomNumber: String { get }
    var playerName: String { get }
    var playerId: String { get }
    var isHost: Bool { get }
    var roomModel: RoomModel { get }
    var showCardSelector: Bool { get }
    var selectedCardIndex: Int? { get }
    var shareableRoomNumber: String { get }
    func reconnect()
    func handleHostAction()
    func selectCard(cardIndex: Int)
    func leaveRoom()
}

@MainActor
final class RoomViewModel: RoomViewModelProtocol {
    private var socketService: SocketServiceProtocol
    private let logger = Logger(subsystem: "teampoint", category: "room")
    
    let roomNumber: String
    let playerName: String
    let playerId: String
    let isHost: Bool
    
    @Published var roomModel: RoomModel
    @Published var showCardSelector: Bool = false
    @Published var selectedCardIndex: Int? = nil
    @Published var error: SocketError? = nil
    @Published var disconected: Bool = false
    
    var shareableRoomNumber: String {
        "TeamPoint: Join room number \(roomNumber)."
    }
    
    init(
        roomNumber: String,
        playerId: String,
        playerName: String,
        isHost: Bool,
        socketService: SocketServiceProtocol
    ) {
        self.roomNumber = roomNumber
        self.playerId = playerId
        self.playerName = playerName
        self.isHost = isHost
    
        let players = [RoomModel.Player(id: playerId, name: playerName)]
        self.roomModel = RoomModel(players: players, state: .lobby)
        
        self.socketService = socketService
        self.socketService.gameDelegate = self
    }
    
    func reconnect() {
        socketService.establishConnection()
    }
    
    func handleHostAction() {
        switch roomModel.state {
        case .lobby, .finished:
            startGame()
        case .selecting(_, _):
            endGame()
        }
    }
    
    func selectCard(cardIndex: Int) {
        selectedCardIndex = selectedCardIndex == cardIndex ? nil : cardIndex
        let playerData = GameData.Player(id: playerId, name: playerName, selectedCardIndex: selectedCardIndex ?? -1)
        socketService.selectCard(roomNumber: roomNumber, player: playerData)
    };
    
    func leaveRoom() {
        logger.log("Leaving room")
        socketService.leaveRoom(roomNumber: roomNumber, playerId: playerId)
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
    
    private func startGame() {
        logger.log("Starting game")
        roomModel.state = .selecting(count: 0, total: roomModel.players.count)
        updateStatePresentation()
        socketService.startGame(roomNumber: roomNumber)
    }
    
    private func endGame() {
        logger.log("Revealing cards")
        updateStatePresentation()
        socketService.endGame(roomNumber: roomNumber)
    }
}

extension RoomViewModel: SocketGameDelegate {
    func didFail(error: SocketError) {
        self.error = error
    }
    
    func didUpdateGame(_ gameData: GameData) {
        let newRoomModel = RoomModel(gameData: gameData)
        self.roomModel = newRoomModel
        self.updateStatePresentation()
    }
    
    func didReconnect() {
        logger.log("Rejoining room")
        socketService.joinRoom(roomNumber: roomNumber, playerId: playerId, playerName: playerName)
    }
}

