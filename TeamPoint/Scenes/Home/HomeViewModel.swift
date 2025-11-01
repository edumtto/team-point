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
    var state: Published<HomeViewState> { get set }
}

enum HomeViewState {
    case start
    case enteringRoomInput
    case creatingRoomInput
    case loadingRoom
    case error(Error)
}

class HomeViewModel: ObservableObject {
    @Published var state: HomeViewState = .start
}

