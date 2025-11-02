//
//  HomeViewModel.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI
import Combine

protocol HomeViewModelProtocol {
    func joinRoom(code: String, playerName: String)
    func createRoom(playerName: String)
    func updateRoomNumber(_ newValue: String)
}

// MARK: - Models
enum RoomError: Error, Identifiable {
    case joinFailed(message: String)
    var id: String {
        switch self {
        case .joinFailed(let message):
            return message
        }
    }
    var localizedDescription: String {
        switch self {
        case .joinFailed(let message):
            return "Failed to join room: \(message)"
        }
    }
}

enum HomeActionType {
    case join, create
}

@MainActor
class HomeViewModel: ObservableObject {
    private var socketService: SocketServiceProtocol
    private let maxRoomNumberLength = 5
    
    @Published var roomNumber: String = ""
    @Published var playerName: String = ""
    @Published var playerId: String = UUID().uuidString
    
    @Published var showNamePopup = false
    @Published var actionType: HomeActionType?
    @Published var error: SocketError?
    @Published var isLoading = false
    @Published var navigateToRoom = false
    
    var isUserHost: Bool {
        actionType == .create
    }
    
    init(socketService: SocketServiceProtocol) {
        self.socketService = socketService
        self.socketService.connectionDelegate = self
    }
    
    func updateRoomNumber(_ newValue: String) {
        // Limit to 5 digits and only allow numbers
        let filtered = newValue.filter { $0.isNumber }
        roomNumber = String(filtered.prefix(maxRoomNumberLength))
    }
    
    func startJoinRoom() {
        actionType = .join
        showNamePopup = true
    }
    
    func startCreateRoom() {
        actionType = .create
        showNamePopup = true
    }
    
    func cancelNameEntry() {
        showNamePopup = false
        playerName = ""
    }
    
    func confirmAction() {
        isLoading = true
        let room = actionType == .join ? roomNumber : getNewRoomNumber()
        socketService.joinRoom(
            roomNumber: room,
            isNewRoom: actionType == .create,
            playerId: playerId, playerName: playerName
        )
    }
    
    private func getNewRoomNumber() -> String {
        // TODO: Consume an API to get a valid newRoomNumber
        String(Int.random(in: 10000...99999))
    }
    
    private func resetForm() {
        showNamePopup = false
//        playerName = ""
    }
    
    var isJoinButtonEnabled: Bool {
        roomNumber.count == maxRoomNumberLength
    }
    
    var isContinueButtonEnabled: Bool {
        !playerName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var popupTitle: String {
        actionType == .join ? "Join Room" : "Create Room"
    }
}

extension HomeViewModel: SocketConnectionDelegate {
    func didFail(error: SocketError) {
        self.error = error
        isLoading = false
    }
    
    func didJoinRoom() {
        isLoading = false
        navigateToRoom = true
        resetForm()
    }
    
}
