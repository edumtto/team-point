//
//  MockSocketService.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 11/2/25.
//

@testable import TeamPoint

@MainActor
final class MockSocketService: SocketServiceProtocol {
    var establishConnectionCallCount = 0
    
    var joinRoomCallCount = 0
    var lastJoinRoomNumber: String?
    var lastJoinRoomPlayerId: String?
    var lastJoinRoonPlayerName: String?
    
    var selectCardCallCount = 0
    var lastSelectedPlayer: GameData.Player?
    
    var leaveRoomCallCount = 0
    var lastLeftRoomNumber: String?
    var lastLeftPlayerId: String?
    
    var startGameCallCount = 0
    var endGameCallCount = 0
    
    weak var connectionDelegate: (any TeamPoint.SocketConnectionDelegate)?
    weak var gameDelegate: SocketGameDelegate?

    func establishConnection() {
        establishConnectionCallCount += 1
    }
    
    func joinRoom(roomNumber: String, playerId: String, playerName: String) {
        joinRoomCallCount += 1
        lastJoinRoomNumber = roomNumber
        lastJoinRoomPlayerId = playerId
        lastJoinRoonPlayerName = playerName
    }
    
    func selectCard(roomNumber: String, player: GameData.Player) {
        selectCardCallCount += 1
        lastSelectedPlayer = player
    }
    
    func leaveRoom(roomNumber: String, playerId: String) {
        leaveRoomCallCount += 1
        lastLeftRoomNumber = roomNumber
        lastLeftPlayerId = playerId
    }
    
    func startGame(roomNumber: String) {
        startGameCallCount += 1
    }
    
    func endGame(roomNumber: String) {
        endGameCallCount += 1
    }
    
    // Helper methods
    
    func simulateSuccess() {
        connectionDelegate?.didJoinRoom()
    }
    
    func simulateError(_ error: SocketError) {
        connectionDelegate?.didFail(error: error)
    }
    
    func simulateUpdate(gameData: GameData) async {
        await MainActor.run {
            gameDelegate?.didUpdateGame(gameData)
        }
    }
}
