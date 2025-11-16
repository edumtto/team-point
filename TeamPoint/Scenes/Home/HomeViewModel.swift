//
//  HomeViewModel.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI
import Combine

protocol HomeViewModelProtocol: ObservableObject, AnyObject {
    var roomNumber: String { get }
    var playerName: String { get }
    var playerId: String { get }
    var showNamePopup: Bool { get }
    var actionType: HomeActionType? { get }
    var error: SocketError? { get }
    var isLoading: Bool { get }
    var navigateToRoom: Bool { get }
    var isUserHost: Bool { get }
    var isJoinButtonEnabled: Bool { get }
    var isContinueButtonEnabled: Bool { get }
    var popupTitle: String { get }
    
    func reconnect()
    func updateRoomNumber(_ newValue: String)
    func startJoinRoom()
    func startCreateRoom()
    func cancelNameEntry()
    func confirmAction()
}

enum HomeActionType {
    case join, create
}

@MainActor
class HomeViewModel: HomeViewModelProtocol {
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
    
    var isJoinButtonEnabled: Bool {
        roomNumber.count == maxRoomNumberLength
    }
    
    var isContinueButtonEnabled: Bool {
        !playerName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var popupTitle: String {
        actionType == .join ? "Join Room" : "Create Room"
    }
    
    init(socketService: SocketServiceProtocol) {
        self.socketService = socketService
        self.socketService.connectionDelegate = self
    }
    
    func reconnect() {
        socketService.establishConnection()
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
        socketService.joinRoom(roomNumber: room, playerId: playerId, playerName: playerName)
        roomNumber = room
    }
    
    private func getNewRoomNumber() -> String {
        // TODO: Consume an API to get a valid newRoomNumber
        String(Int.random(in: 10000...99999))
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
        showNamePopup = false
    }
    
}
