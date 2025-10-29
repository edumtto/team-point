//
//  SessionData.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

// Dados de um usuário
struct User: Identifiable, Codable {
    let id: String // ID único (ex: Socket ID)
    let name: String
    var hasVoted: Bool = false // Se o usuário já votou nesta história
}

// Dados de uma história (item a ser estimado)
struct Story: Identifiable, Codable {
    let id: String
    let title: String
    var isRevealed: Bool = false
    var votes: [String: Int] = [:] // [UserID: Voto]
}

// Representação de toda a sala de Poker
struct SessionData: Codable {
    let roomID: String
    let moderatorID: String
    var users: [User]
    var stories: [Story] // Lista de histórias
    var currentStoryID: String? // A história que está sendo votada
}

enum SessionState {
    // 1. Estados de Conexão
    case connecting
    case disconnected(reason: String)
    case error(message: String)

    // 2. Estados da Sessão (com dados)
    case Home(sessionData: SessionData)
    case voting(sessionData: SessionData)      // Votação em andamento (votos escondidos)
    case results(sessionData: SessionData)     // Votação revelada
}
