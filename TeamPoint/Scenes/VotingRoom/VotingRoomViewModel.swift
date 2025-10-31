//
//  VotingRoomViewModel.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

protocol VotingRoomProtocol {
    func startVoting()
    func vote(points: Int, username: String)
    func revealVotes()
    func restartVoting()
    var isHost: Bool { get }
}

enum VotingRoomState {
    case waitingParticipants
    case voting
    case revealingVotes
}
