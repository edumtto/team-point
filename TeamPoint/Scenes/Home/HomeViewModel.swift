//
//  HomeViewModel.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//
import SwiftUI
internal import Combine

protocol HomeViewModelProtocol {
    func enterRoom(code: Int)
    func createRoom()
}

enum HomeViewState {
    case start
    case loading
    case error(Error)
    case enteringName
    case enteringRoom(roomId: Int, userName: String, isHost: Bool)
}

class HomeViewModel: ObservableObject {
    @Published var state: HomeViewState = .start
}
