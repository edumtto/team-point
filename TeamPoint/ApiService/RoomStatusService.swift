//
//  HomeNetworkService.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 11/2/25.
//

// TODO
/*
import Foundation

struct RoomStatusResponse: Decodable {
    let found: Bool
}

struct NewRoomNumberResponse: Decodable {
    let roomNumber: String
}

protocol RoomStatusServiceProtocol {
    func checkRoomAvailable(for roomNumber: String) async throws -> Bool
}

class RoomStatusService {
    private let networkManager: NetworkManager
    private let baseURL = GlobalConstants.baseURL

    init(networkManager: NetworkManager = NetworkManager()) {
        self.networkManager = networkManager
    }

    func checkRoomAvailable(for roomNumber: String) async throws -> Bool {
        let endpoint = "/api/room/status/\(roomNumber)"
        let url = baseURL.appendingPathComponent(endpoint)
        let status: RoomStatusResponse = try await networkManager.request(url: url)
        return status.found
    }
    
    func getNewRoomNumber() async throws -> String {
        let endpoint = "/api/room/newNumber"
        let url = baseURL.appendingPathComponent(endpoint)
        let response: NewRoomNumberResponse = try await networkManager.request(url: url)
        return response.roomNumber
    }
}
*/
