//
//  SocketService.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI
import Combine
import SocketIO

protocol SocketConnectionDelegate: AnyObject {
    func didJoinRoom()
    func didFail(error: SocketError)
}

protocol SocketGameDelegate: AnyObject {
    func didFail(error: SocketError)
    func didUpdateGame(_ gameData: GameData)
}

protocol SocketServiceProtocol {
    func establishConnection()
    func joinRoom(roomNumber: String, playerId: String, playerName: String)
    func leaveRoom(roomNumber: String, playerId: String)
    
    func startGame(roomNumber: String)
    func selectCard(roomNumber: String,player: GameData.Player)
    func endGame(roomNumber: String)
    
    var connectionDelegate: SocketConnectionDelegate? { get set }
    var gameDelegate: SocketGameDelegate? { get set }
}

final class SocketService: ObservableObject {
    static let shared = SocketService()
    
    private enum Event: String {
        // Client -> Server
        case join
        case leave
        case startGame
        case selectCard
        case endGame
        
        // Server -> Client
        case updateGame
        
        var name: String { rawValue }
    }
    
    enum EventAck: String {
        case success
        case failure
        
        var value: String { rawValue }
    }
    
    private let manager: SocketManager
    private let socket: SocketIOClient
    weak var connectionDelegate: SocketConnectionDelegate?
    weak var gameDelegate: SocketGameDelegate?
    
    var isConnected: Bool {
        return socket.status == .connected
    }
    
    init () {
        self.manager = SocketManager(socketURL: GlobalConstants.baseURL, config: [.log(false), .reconnectAttempts(5), .reconnectWait(3), .compress])
        self.socket = manager.defaultSocket
        setupEventListeners()
        establishConnection()
    }
    
    private func setupEventListeners() {
        socket.on(clientEvent: .connect) { data, ack in
            print("Socket connected!")
        }
        
        socket.on(clientEvent: .disconnect) { data, ack in
            print("Socket disconnected.")
        }
        
        socket.on(clientEvent: .error) { data, ack in
            if let error = data.first as? Error {
                print("Socket error: \(error.localizedDescription)")
            } else {
                print("Socket error: \(data)")
            }
        }
        
        socket.on(Event.updateGame.name) { [weak self] data, ack in
            guard let self, let payload = data.first as? [String: Any] else {
                print("Error: 'join' event received but no valid payload found.")
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(GameData.self, from: jsonData)
                self.gameDelegate?.didUpdateGame(decodedData)
            } catch {
                print("❌ Decoding Error for 'updateGame' event: \(error)")
            }
        }
    }
    
    private func logEmitError(_ error: SocketError, eventName: String) {
        switch error {
        case .notConnected, .notJoined:
            print("Socket not connected. Cannot emit '\(eventName)'.")
        }
    }
}

extension SocketService: SocketServiceProtocol {
    func establishConnection() {
        if socket.status != .connected {
            socket.connect(timeoutAfter: 5) { [weak self] in
                self?.connectionDelegate?.didFail(error: .notConnected)
            }
        }
    }
    
    func joinRoom(roomNumber: String, playerId: String, playerName: String) {
        guard isConnected else {
            connectionDelegate?.didFail(error: .notConnected)
            socket.connect()
            return
        }
        
        let data: [String : Any] = [
            "roomNumber": roomNumber,
            "playerId": playerId,
            "playerName": playerName
        ]
        
        socket.emitWithAck("join", data).timingOut(after: 1) { [weak self] ackData in
            guard let ack = ackData.first as? String, ack == EventAck.success.value else {
                return
            }
            self?.connectionDelegate?.didJoinRoom()
        }
        print("Emitted 'join' event for:\nchannel: \(roomNumber)\nplayerId: \(playerId)\nplayerName: \(playerName)")
    }
    
    func leaveRoom(roomNumber: String, playerId: String) {
        guard isConnected else {
            return
        }
        
        let data: [String : Any] = [
            "roomNumber": roomNumber,
            "playerId": playerId
        ]
        
        socket.emit(Event.leave.name, data)
    }
    
    func startGame(roomNumber: String) {
        guard isConnected else {
            gameDelegate?.didFail(error: .notConnected)
            logEmitError(.notConnected, eventName: Event.startGame.name)
            return
        }
        
        let data: [String : Any] = [
            "roomNumber": roomNumber,
        ]
        
        socket.emit(Event.startGame.name, data)
    }
    
    func endGame(roomNumber: String) {
        guard isConnected else {
            gameDelegate?.didFail(error: .notConnected)
            logEmitError(.notConnected, eventName: Event.endGame.name)
            return
        }
        
        let data: [String : Any] = [
            "roomNumber": roomNumber,
        ]
        
        socket.emit(Event.endGame.name, data)
    }
    
    func selectCard(roomNumber: String, player: GameData.Player) {
        guard isConnected else {
            gameDelegate?.didFail(error: .notConnected)
            logEmitError(.notConnected, eventName: Event.selectCard.name)
            return
        }
        
        let data: [String: Any] = [
            "roomNumber": roomNumber,
            "playerId": player.id,
            "cardIndex": player.selectedCardIndex
        ]
        
        socket.emit(Event.selectCard.name, data)
    }
}
