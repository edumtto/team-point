//
//  SocketService.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI
import Combine
import SocketIO


struct GameData: Decodable {
    struct Player: Identifiable, Codable, SocketData {
        let id: String
        let name: String
        let selectedCardIndex: Int // -1 represents no card selected
        
        init(id: String, name: String, selectedCardIndex: Int = -1) {
            self.id = id
            self.name = name
            self.selectedCardIndex = selectedCardIndex
        }
        
        func jsonData() -> [String: Any]? {
            do {
               let jsonData = try JSONEncoder().encode(self)
                return try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
           } catch {
               print("Error encoding struct: \(error)")
               return nil
           }
        }
    
    }
    
    enum State: Decodable {
        case waiting
        case started
        case ended
    }
    
    let players: [Player]
    let state: State
}

enum SocketError: Error {
    case notConnected
    
    var message: String {
        switch self {
        case .notConnected:
            return "Error connecting. Check your internet connection."
        }
    }
}

enum GlobalConstants {
    static let socketURL = URL(string: "http://localhost:3000")!
}

protocol SocketEventsDelegate: AnyObject {
    func didJoinRoom()
    func didFail(error: SocketError)
    func didCloseConnection()
    
    func didUpdateGame(_ gameData: GameData)
}

protocol SocketServiceProtocol {
    func establishConnection()
    func joinChannel(_ channelName: String, retryConnecting: Bool)
    func closeConnection()
    
    func startGame()
    func enterRoom(player: GameData.Player)
    func selectCard(player: GameData.Player)
    func endGame()
    
    var delegate: SocketEventsDelegate? { get set }
}

final class SocketService: ObservableObject, SocketServiceProtocol {
    static let shared = SocketService()
    
    private enum Event: String {
        // Client -> Server
        case enterRoom
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
    
    func joinChannel(_ channelName: String, retryConnecting: Bool = false) {
        guard socket.status == .connected else {
            if retryConnecting {
                socket.connect(timeoutAfter: 2) { [weak self] in
                    self?.joinChannel(channelName)
                }
            } else {
                delegate?.didFail(error: .notConnected)
                print("Socket not connected. Cannot emit 'join'.")
            }
            
            return
        }
        
        socket.emit("join", channelName) { [weak self] in
            self?.delegate?.didJoinRoom()
        }
        print("Emitted 'join' event for channel: \(channelName)")
    }
    
    func startGame() {
        guard socket.status == .connected else {
            delegate?.didFail(error: .notConnected)
            print("Socket not connected. Cannot emit 'enterRoom'.")
            return
        }
        
        socket.emit(Event.startGame.name)
    }
    
    func endGame() {
        socket.emit(Event.endGame.name)
    }
    
    func enterRoom(player: GameData.Player) {
        guard socket.status == .connected else {
            delegate?.didFail(error: .notConnected)
            print("Socket not connected. Cannot emit 'enterRoom'.")
            return
        }
        
        let data: [String: Any] = [
            "playerId": player.id,
            "playerName": player.name
        ]
        socket.emit(Event.enterRoom.name, data)
    }

    func selectCard(player: GameData.Player) {
        guard socket.status == .connected else {
            delegate?.didFail(error: .notConnected)
            print("Socket not connected. Cannot emit 'SelectedCard'.")
            return
        }
        
        let data: [String: Any] = [
            "playerId": player.id,
            "cardId": player.selectedCardIndex
        ]
        
        socket.emit(Event.selectCard.name, data)
    }
}

