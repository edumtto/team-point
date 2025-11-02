//
//  HomeViewModel.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//
import SwiftUI
import Combine

protocol HomeViewModelProtocol {
    func enterRoom(code: String, username: String)
    func createRoom(username: String)
    func updateRoomNumber(_ newValue: String)
}

// MARK: - Models


//struct RoomInfo {
//    let roomNumber: String?
//    let userName: String
//    let actionType: ActionType
//}

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
    
    @Published var roomNumber: String = ""
    @Published var userName: String = ""
    @Published var showNamePopup = false
    @Published var actionType: HomeActionType?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var navigateToRoom = false
    
    private let maxRoomNumberLength = 5
    
    init(socketService: SocketServiceProtocol) {
        self.socketService = socketService
        self.socketService.delegate = self
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
        userName = ""
        errorMessage = nil
    }
    
    func confirmAction() {
        isLoading = true
        
        if actionType == .join {
            print("Trying to join room \(roomNumber)")
            socketService.joinChannel(roomNumber)
        } else {
            let newRoomNumber = String(Int.random(in: 10000...99999))
            print("Trying to creat room \(roomNumber)")
            socketService.joinChannel(newRoomNumber)
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        
        // Auto-dismiss error after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.errorMessage = nil
        }
    }
    
    private func resetForm() {
        showNamePopup = false
        userName = ""
        errorMessage = nil
    }
    
    var isJoinButtonEnabled: Bool {
        roomNumber.count == maxRoomNumberLength
    }
    
    var isContinueButtonEnabled: Bool {
        !userName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var popupTitle: String {
        actionType == .join ? "Join Room" : "Create Room"
    }
}

extension HomeViewModel: SocketEventsDelegate {
    func didFail(error: SocketError) {
        errorMessage = error.message
        isLoading = false
    }
    
    func didJoinRoom() {
        isLoading = false
        navigateToRoom = true
        resetForm()
    }
    
    func didCloseConnection() {
        
    }
    
    func didStartVoting() {
        
    }
    
    func didReceiveVote(_ vote: Vote) {
        
    }
    
    func didReveal() {
        
    }
}
