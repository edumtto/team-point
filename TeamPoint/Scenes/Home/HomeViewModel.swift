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
enum ActionType {
    case join, create
}

//struct RoomInfo {
//    let roomNumber: String?
//    let userName: String
//    let actionType: ActionType
//}


class HomeViewModel: ObservableObject {
    private let socketService: SocketServiceProtocol
    
    @Published var roomNumber: String = ""
    @Published var userName: String = ""
    @Published var showNamePopup = false
    @Published var actionType: ActionType?
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var navigateToRoom = false
    
    private let maxRoomNumberLength = 5
    
    init(socketService: SocketServiceProtocol) {
        self.socketService = socketService
        stabilishSocketConnection()
    }
    
    private func stabilishSocketConnection() {
        socketService.establishConnection()
    }
    
    func updateRoomNumber(_ newValue: String) {
        // Limit to 5 digits and only allow numbers
        let filtered = newValue.filter { $0.isNumber }
        roomNumber = String(filtered.prefix(maxRoomNumberLength))
    }
    
    func validateAndJoinRoom() {
        guard roomNumber.count == maxRoomNumberLength else {
            showErrorMessage("Please enter a valid 5-digit room code")
            return
        }
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
        let trimmedName = userName.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedName.isEmpty else {
            showErrorMessage("Please enter your name")
            return
        }
        
        guard trimmedName.count >= 2 else {
            showErrorMessage("Name must be at least 2 characters")
            return
        }
        
        // Success - proceed with action
        if actionType == .join {
            print("Joining room \(roomNumber) as \(trimmedName)")
        } else {
            print("Creating room as \(trimmedName)")
        }
        
        navigateToRoom = true
        resetForm()
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        // Auto-dismiss error after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showError = false
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

