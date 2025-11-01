//
//  SocketService.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI
import Combine
import SocketIO

private enum CustomSocketEvent: String {
    case startVoting
    case vote
    case reveal
    
    var name: String { rawValue }
}

struct Vote: Codable, SocketData {
    let username: String
    let points: Int
}

protocol SocketServiceProtocol {
    func establishConnection()
    func closeConnection()
    func joinChannel(_ channelName: String)
    func vote(_ vote: Vote)
}

protocol SocketEventsDelegate: AnyObject {
    func didEstablishConnection()
    func didCloseConnection()
    func didStartVoting()
    func didReceiveVote(_ vote: Vote)
    func didReveal()
}

enum Constants {
    static let socketURL = URL(string: "http://localhost:3000")!
}

final class SocketService: ObservableObject, SocketServiceProtocol {
    private let socket: SocketIOClient
    weak var delegate: SocketEventsDelegate?
//    var onReceiveMessage: ((Message) -> Void)?
    
    var isConnected: Bool {
        return socket.status == .connected
    }

    init(socket: SocketIOClient = SocketManager(socketURL: Constants.socketURL, config: [.log(false), .compress]).defaultSocket) {
        self.socket = socket
        setupSocketEvents()
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
        
//        socket.on("connect_error") { data, ack in
//            if let error = data.first as? String {
//                print("Connection error: \(error)")
//            } else {
//                print("Connection error: \(data)")
//            }
//        }

        // Custom application events
        socket.on(CustomSocketEvent.startVoting.name) { [weak self] data, ack in
            if let self {
                self.delegate?.didStartVoting()
            }
        }
        
        socket.on(CustomSocketEvent.vote.name) { [weak self] data, ack in
//            delegate?.didReceiveVote(<#T##vote: Vote##Vote#>)
        }
        
        socket.on(CustomSocketEvent.reveal.name) { [weak self] data, ack in
            if let self {
                self.delegate?.didReveal()
        }
        
        
//            guard let self = self, let jsonArray = data.first as? [String: Any] else {
//                print("Received non-message data or data format error.")
//                return
//            }

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
        }
    }

    /// Connects the socket.
    func establishConnection() {
        socket.connect()
        delegate?.didEstablishConnection()
    }

    /// Disconnects the socket.
    func closeConnection() {
        socket.disconnect()
        delegate?.didCloseConnection()
    }
    
    func joinChannel(_ channelName: String) {
        guard socket.status == .connected else {
            print("Socket not connected. Cannot emit 'join'.")
            return
        }
        
        socket.emit("join", channelName)
        print("Emitted 'join' event for channel: \(channelName)")
    }

    func vote(_ vote: Vote) {
        guard socket.status == .connected else {
            print("Socket not connected. Cannot emit 'join'.")
            return
        }
        
        socket.emit("vote", vote)
    }
}

