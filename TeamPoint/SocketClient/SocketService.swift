//
//  SocketService.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI
import Combine
import SocketIO
import OSLog

protocol SocketConnectionDelegate: AnyObject {
    func didJoinRoom()
    func didFail(error: SocketError)
}

protocol SocketGameDelegate: AnyObject {
    func didFail(error: SocketError)
    func didUpdateGame(_ gameData: GameData)
    func didDisconnect()
    func didReconnect()
}

protocol SocketServiceProtocol {
    func establishConnection()
    func joinRoom(create: Bool, roomNumber: String, playerId: String, playerName: String)
    func leaveRoom(roomNumber: String, playerId: String)
    
    func startGame(roomNumber: String)
    func selectCard(roomNumber: String,player: GameData.Player)
    func endGame(roomNumber: String)
    
    var connectionDelegate: SocketConnectionDelegate? { get set }
    var gameDelegate: SocketGameDelegate? { get set }
}

final class SocketService: ObservableObject {
    static let shared = SocketService()
    
    private let manager: SocketManager
    private let socket: SocketIOClient
    private let logger = Logger(subsystem: "teampoint", category: "socket")
    
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
    
    private enum EventAck: String {
        case success
        case failure
        
        var value: String { rawValue }
    }
    
    weak var connectionDelegate: SocketConnectionDelegate?
    weak var gameDelegate: SocketGameDelegate?
    
    var isConnected: Bool {
        return socket.status == .connected
    }
    
    init () {
        self.manager = SocketManager(socketURL: GlobalConstants.baseURL, config: [.log(false), .reconnects(false), .compress])
        self.socket = manager.defaultSocket
        setupEventListeners()
        establishConnection()
    }
    
    private func setupEventListeners() {
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            guard let self else { return }
            self.logger.log("Socket connected.")
            self.gameDelegate?.didReconnect()
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            guard let self else { return }
            self.logger.log("Socket disconnected.")
            self.gameDelegate?.didDisconnect()
        }
        
        socket.on(clientEvent: .error) { [weak self] data, ack in
            guard let self else { return }
            self.logger.log("Socket error: \(data)")
            
            let isEmittingError = (data.first as? String)?.contains("emitting") ?? false
            let error: SocketError = isEmittingError ? .emittingFailed : .connectionFailed
            self.gameDelegate?.didFail(error: error)
            self.connectionDelegate?.didFail(error: error)
        }
        
        socket.on(Event.updateGame.name) { [weak self] data, ack in
            guard let self, let payload = data.first as? [String: Any] else {
                self?.logger.error("'join' event received but no valid payload found.")
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(GameData.self, from: jsonData)
                self.gameDelegate?.didUpdateGame(decodedData)
            } catch {
                self.logger.error("Decoding Error for 'updateGame' event: \(error)")
            }
        }
    }
}

extension SocketService: SocketServiceProtocol {
    func establishConnection() {
        if socket.status == .notConnected || socket.status == .disconnected {
            socket.connect(timeoutAfter: 5) {}
        }
    }
    
    func joinRoom(create: Bool, roomNumber: String, playerId: String, playerName: String) {
        let params: [String : Any] = [
            "create": create,
            "roomNumber": roomNumber,
            "playerId": playerId,
            "playerName": playerName
        ]
        
        socket.emitWithAck("join", params).timingOut(after: 1) { [weak self] ackData in
            guard let self, let ack = ackData.first as? String, let result = EventAck(rawValue: ack) else {
                return
            }
            
            switch result {
            case .success:
                self.connectionDelegate?.didJoinRoom()
            case .failure:
                self.connectionDelegate?.didFail(error: .roomNotFound)
            }
        }
        logger.log("Emitted 'join' event for:\nchannel: \(roomNumber)\nplayerId: \(playerId)\nplayerName: \(playerName)")
    }
    
    func leaveRoom(roomNumber: String, playerId: String) {
        let params: [String : Any] = [
            "roomNumber": roomNumber,
            "playerId": playerId
        ]
        
        socket.emit(Event.leave.name, params)
    }
    
    func startGame(roomNumber: String) {
        let params: [String : Any] = [
            "roomNumber": roomNumber,
        ]
        
        socket.emit(Event.startGame.name, params)
    }
    
    func endGame(roomNumber: String) {
        let params: [String : Any] = [
            "roomNumber": roomNumber,
        ]
        
        socket.emit(Event.endGame.name, params)
    }
    
    func selectCard(roomNumber: String, player: GameData.Player) {
        let params: [String: Any] = [
            "roomNumber": roomNumber,
            "playerId": player.id,
            "cardIndex": player.selectedCardIndex
        ]

        socket.emit(Event.selectCard.name, params)
    }
}
