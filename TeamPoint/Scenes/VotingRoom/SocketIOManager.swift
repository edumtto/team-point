//
//  SocketIOManager.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI
import SocketIO


struct Message: Identifiable, Codable {
    var id = UUID()
    let sender: String
    let text: String
    var timestamp: Date = Date()

    // Example event names for clarity
    static let chatEvent = "chatMessage"
}

final class SocketIOManager {
    // Replace with your actual Socket.IO server URL
    private let serverURL = URL(string: "http://localhost:3000")!
    private var manager: SocketManager!
    private var socket: SocketIOClient!

    // Closure to handle incoming messages received by the socket
    var onReceiveMessage: ((Message) -> Void)?

    init() {
        // Configure SocketManager
        manager = SocketManager(socketURL: serverURL, config: [.log(false), .compress])
        socket = manager.defaultSocket
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
            print("Socket error: \(data)")
        }

        // Custom application events
        socket.on(Message.chatEvent) { [weak self] data, ack in
            guard let self = self, let jsonArray = data.first as? [String: Any] else {
                print("Received non-message data or data format error.")
                return
            }

            // Simple example parsing: Expecting a dictionary with 'sender' and 'text'
            if let sender = jsonArray["sender"] as? String,
               let text = jsonArray["text"] as? String {

                let newMessage = Message(sender: sender, text: text)
                print("Received message from \(newMessage.sender): \(newMessage.text)")

                // Call the handler closure in the ViewModel
                self.onReceiveMessage?(newMessage)
            } else {
                print("Failed to parse incoming message data.")
            }

            // Example of sending an acknowledgement if required by the server
            // ack.with("Got it!")
        }
    }

    /// Connects the socket.
    func establishConnection() {
        socket.connect()
    }

    /// Disconnects the socket.
    func closeConnection() {
        socket.disconnect()
    }

    /// Sends a message object to the server.
    /// - Parameters:
    ///   - sender: The name of the sender.
    ///   - text: The content of the message.
    func sendMessage(sender: String, text: String) {
        let messageData: [String: Any] = [
            "sender": sender,
            "text": text
        ]

        // Emit the message data to the server under the predefined event name
        socket.emit(Message.chatEvent, messageData)
        print("Sent message: \(text) by \(sender)")
    }

    /// Checks if the socket is currently connected.
    var isConnected: Bool {
        return socket.status == .connected
    }
}
