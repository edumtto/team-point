//
//  SocketService.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI
import Combine
import SocketIO

protocol SocketEventsDelegate: AnyObject {
    func didJoinRoom()
    func didFail(error: SocketError)
    func didCloseConnection()
    
    func didUpdateGame(_ gameData: GameData)
}

protocol SocketServiceProtocol {
    func establishConnection()
    func joinRoom(_ roomNumber: String, playerId: String, playerName: String, retryConnecting: Bool)
    func closeConnection()

    func startGame()
    func selectCard(player: GameData.Player)
    func endGame()
    
    var delegate: SocketEventsDelegate? { get set }
}

final class SocketService: ObservableObject {
    static let shared = SocketService()
    
    private enum Event: String {
        // Client -> Server
        case join
        case startGame
        case selectCard
        case endGame
        
        // Server -> Client
        case updatedGame
        
        var name: String { rawValue }
    }
    
    private let manager: SocketManager
    private let socket: SocketIOClient
    weak var delegate: SocketEventsDelegate?
    
    var isConnected: Bool {
        return socket.status == .connected
    }
    
    //init(socket: SocketIOClient = SocketManager(socketURL: Constants.socketURL, config: [.log(false), .reconnectAttempts(3), .reconnectWait(1), .compress]).defaultSocket) {
    init () {
        self.manager = SocketManager(socketURL: GlobalConstants.socketURL, config: [.log(false), .reconnectAttempts(3), .reconnectWait(1), .compress])
        self.socket = manager.defaultSocket
        setupSocketEvents()
        establishConnection()
    }
    
    /// Sets up all necessary Socket.IO event listeners.
    private func setupSocketEvents() {
        // Connection events
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
        
        // Custom application events
        //        socket.on(Event.updatedGame.name) { [weak self] data, ack in
        //            guard let self, let jsonArray = data.first as? [String: Any] else {
        //                print("Received non-message data or data format error.")
        //                return
        //            }
        //            self.delegate?.didUpdateGame(GameData(players: [], state: .waiting))
        //        }
        //
        
        // Simple example parsing: Expecting a dictionary with 'sender' and 'text'
        //            if let sender = jsonArray["sender"] as? String,
        //               let text = jsonArray["text"] as? String {
        //
        //                let newMessage = Message(sender: sender, text: text)
        //                print("Received message from \(newMessage.sender): \(newMessage.text)")
        //
        //                // Call the handler closure in the ViewModel
        //                self.onReceiveMessage?(newMessage)
        //            } else {
        //                print("Failed to parse incoming message data.")
        //            }
        
        // Example of sending an acknowledgement if required by the server
        // ack.with("Got it!")
        //        }
    }
    
    private func logEmitError(_ error: SocketError, eventName: String) {
        switch error {
        case .notConnected:
            print("Socket not connected. Cannot emit '\(eventName)'.")
        }
    }
}

extension SocketService: SocketServiceProtocol {
    func establishConnection() {
        if socket.status != .connected {
            socket.connect(timeoutAfter: 2) { [weak self] in
                self?.delegate?.didFail(error: .notConnected)
            }
        }
    }

    func closeConnection() {
        socket.disconnect()
        delegate?.didCloseConnection()
    }
    
    func joinRoom(_ roomNumber: String, playerId: String, playerName: String, retryConnecting: Bool = false) {
        guard isConnected else {
            if retryConnecting {
                socket.connect(timeoutAfter: 2) { [weak self] in
                    self?.joinRoom(roomNumber, playerId: playerId, playerName: playerName)
                }
            } else {
                delegate?.didFail(error: .notConnected)
                logEmitError(.notConnected, eventName: Event.join.name)
            }
            
            return
        }
        
        let data = [
            "roomNumber": roomNumber,
            "playerId": playerId,
            "playerName": playerName
        ]
        
        socket.emit("join", data) { [weak self] in
            self?.delegate?.didJoinRoom()
        }
        print("Emitted 'join' event for:\nchannel: \(roomNumber)\nplayerId: \(playerId)\nplayerName: \(playerName)")
    }
    
    func startGame() {
        guard isConnected else {
            delegate?.didFail(error: .notConnected)
            logEmitError(.notConnected, eventName: Event.startGame.name)
            return
        }
        
        socket.emit(Event.startGame.name)
    }
    
    func endGame() {
        guard isConnected else {
            delegate?.didFail(error: .notConnected)
            logEmitError(.notConnected, eventName: Event.endGame.name)
            return
        }
        socket.emit(Event.endGame.name)
    }

    func selectCard(player: GameData.Player) {
        guard isConnected else {
            delegate?.didFail(error: .notConnected)
            logEmitError(.notConnected, eventName: Event.selectCard.name)
            return
        }
        
        let data: [String: Any] = [
            "playerId": player.id,
            "cardId": player.selectedCardIndex
        ]
        
        socket.emit(Event.selectCard.name, data)
    }
}
