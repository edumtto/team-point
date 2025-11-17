//
//  TeamPointTests.swift
//  TeamPointTests
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import XCTest
import Combine
@testable import TeamPoint

@MainActor
final class RoomViewModelTests: XCTestCase {
    
    var sut: RoomViewModel!
    var mockSocketService: MockSocketService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockSocketService = MockSocketService()
        cancellables = []
        
        sut = RoomViewModel(
            roomNumber: "1234",
            playerId: "player1",
            playerName: "John",
            isHost: true,
            socketService: mockSocketService
        )
    }
    
    override func tearDown() {
        mockSocketService.connectionDelegate = nil
        mockSocketService.gameDelegate = nil
        sut = nil
        mockSocketService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_SetsPropertiesCorrectly() {
        XCTAssertEqual(sut.roomNumber, "1234")
        XCTAssertEqual(sut.playerId, "player1")
        XCTAssertEqual(sut.playerName, "John")
        XCTAssertTrue(sut.isHost)
    }
    
    func testInitialization_CreatesInitialRoomModel() {
        XCTAssertEqual(sut.roomModel.players.count, 1)
        XCTAssertEqual(sut.roomModel.players.first?.id, "player1")
        XCTAssertEqual(sut.roomModel.players.first?.name, "John")
        XCTAssertEqual(sut.roomModel.state, .lobby)
    }
    
    func testInitialization_SetsDefaultValues() {
        XCTAssertFalse(sut.showCardSelector)
        XCTAssertNil(sut.selectedCardIndex)
    }
    
    func testInitialization_SetsGameDelegate() {
        XCTAssertTrue(mockSocketService.gameDelegate === sut)
    }
    
    func testInitialization_NonHostPlayer() async {
        // Keep instance alive for the duration of the test and yield once to avoid
        // teardown/deinit racing with other callbacks on the main actor.
        let nonHostViewModel = RoomViewModel(
            roomNumber: "5678",
            playerId: "player2",
            playerName: "Jane",
            isHost: false,
            socketService: mockSocketService
        )
        
        XCTAssertFalse(nonHostViewModel.isHost)
        XCTAssertEqual(nonHostViewModel.roomNumber, "5678")
        XCTAssertTrue(mockSocketService.gameDelegate === nonHostViewModel)
        
        // Allow main actor to process any pending tasks before the function returns
        // which helps avoid deinit racing with other main-actor work.
        await Task.yield()
    }
    
    // MARK: - Reconnect Tests
    func testReconnect_EstablishConnection() {
        sut.reconnect()
        
        XCTAssertEqual(mockSocketService.establishConnectionCallCount, 1)
        XCTAssertNil(sut.error)
        XCTAssertTrue(sut.isReconnecting)
    }
    
    // MARK: - Shareable Room Number Tests
    
    func testShareableRoomNumber_ReturnsCorrectFormat() {
        XCTAssertEqual(sut.shareableRoomNumber, "TeamPoint: Join room number 1234.")
    }
    
    // MARK: - Host Action Tests
    
    func testHandleHostAction_InLobbyState_StartsGame() {
        sut.handleHostAction()
        
        XCTAssertEqual(mockSocketService.startGameCallCount, 1)
        XCTAssertTrue(sut.showCardSelector)
    }
    
    func testHandleHostAction_InFinishedState_StartsGame() {
        sut.roomModel.state = .finished(averageScore: 1.0)
        
        sut.handleHostAction()
        
        XCTAssertEqual(mockSocketService.startGameCallCount, 1)
        XCTAssertTrue(sut.showCardSelector)
    }
    
    func testHandleHostAction_InSelectingState_EndsGame() {
        sut.roomModel.state = .selecting(count: 2, total: 3)
        
        sut.handleHostAction()
        
        XCTAssertEqual(mockSocketService.endGameCallCount, 1)
    }
    
    func testHandleHostAction_UpdatesRoomState() {
        XCTAssertEqual(sut.roomModel.state, .lobby)
        
        sut.handleHostAction()
        
        if case .selecting(let count, let total) = sut.roomModel.state {
            XCTAssertEqual(count, 0)
            XCTAssertEqual(total, 1)
        } else {
            XCTFail("Expected selecting state")
        }
    }
    
    // MARK: - Card Selection Tests
    
    func testSelectCard_FirstSelection_SetsSelectedCardIndex() {
        sut.selectCard(cardIndex: 3)
        
        XCTAssertEqual(sut.selectedCardIndex, 3)
        XCTAssertEqual(mockSocketService.selectCardCallCount, 1)
    }
    
    func testSelectCard_SecondSelection_DeselectsCard() {
        sut.selectCard(cardIndex: 3)
        sut.selectCard(cardIndex: 3)
        
        XCTAssertNil(sut.selectedCardIndex)
        XCTAssertEqual(mockSocketService.selectCardCallCount, 2)
    }
    
    func testSelectCard_DifferentCard_UpdatesSelection() {
        sut.selectCard(cardIndex: 2)
        sut.selectCard(cardIndex: 5)
        
        XCTAssertEqual(sut.selectedCardIndex, 5)
        XCTAssertEqual(mockSocketService.selectCardCallCount, 2)
    }
    
    func testSelectCard_SendsCorrectPlayerData() {
        sut.selectCard(cardIndex: 4)
        
        XCTAssertEqual(mockSocketService.lastSelectedPlayer?.id, "player1")
        XCTAssertEqual(mockSocketService.lastSelectedPlayer?.name, "John")
        XCTAssertEqual(mockSocketService.lastSelectedPlayer?.selectedCardIndex, 4)
    }
    
    func testSelectCard_Deselection_SendsNegativeIndex() {
        sut.selectCard(cardIndex: 3)
        sut.selectCard(cardIndex: 3)
        
        XCTAssertEqual(mockSocketService.lastSelectedPlayer?.selectedCardIndex, -1)
    }
    
    // MARK: - Leave Room Tests
    
    func testLeaveRoom_CallsSocketService() {
        sut.leaveRoom()
        
        XCTAssertEqual(mockSocketService.leaveRoomCallCount, 1)
        XCTAssertEqual(mockSocketService.lastLeftRoomNumber, "1234")
        XCTAssertEqual(mockSocketService.lastLeftPlayerId, "player1")
    }
    
    // MARK: - Socket Delegate Tests (didUpdateGame)
    
    func testDidUpdateGame_UpdatesRoomModel() async {
        let players = [
            GameData.Player(id: "12345", name: "John", selectedCardIndex: 2),
            GameData.Player(id: "54321", name: "Jane", selectedCardIndex: 5)
        ]
        let gameData = GameData(
            players: players,
            state: .selecting
        )
        
        await mockSocketService.simulateUpdate(gameData: gameData)
        
        XCTAssertEqual(sut.roomModel.players.count, 2)
        XCTAssertEqual(sut.roomModel.players[0].name, "Jane")
        XCTAssertEqual(sut.roomModel.players[1].name, "John")
    }
    
    func testDidUpdateGame_UpdatesStatePresentation_ToSelecting() async {
        let gameData = GameData(
            players: [GameData.Player(id: "player1", name: "John", selectedCardIndex: -1)],
            state: .selecting
        )
        
        await mockSocketService.simulateUpdate(gameData: gameData)
        
        XCTAssertTrue(sut.showCardSelector)
    }
    
    func testDidUpdateGame_UpdatesStatePresentation_ToFinished() async {
        sut.roomModel.state = .selecting(count: 1, total: 1)
        sut.showCardSelector = true
        sut.selectedCardIndex = 3
        
        let gameData = GameData(
            players: [GameData.Player(id: "player1", name: "John", selectedCardIndex: 3)],
            state: .finished
        )
        
        await mockSocketService.simulateUpdate(gameData: gameData)
        
        XCTAssertFalse(sut.showCardSelector)
        XCTAssertNil(sut.selectedCardIndex)
    }
    
    func testDidUpdateGame_UpdatesStatePresentation_ToLobby()  async{
        sut.roomModel.state = .selecting(count: 1, total: 1)
        sut.showCardSelector = true
        sut.selectedCardIndex = 3
        
        let gameData = GameData(
            players: [GameData.Player(id: "player1", name: "John", selectedCardIndex: -1)],
            state: .lobby
        )
        
        await mockSocketService.simulateUpdate(gameData: gameData)
        
        XCTAssertFalse(sut.showCardSelector)
        XCTAssertNil(sut.selectedCardIndex)
    }
    
    // Additional didUpdateGame coverage: finished average computation does not toggle reconnecting
    func testDidUpdateGame_ToFinished_ComputesAverageAndKeepsReconnectingUntouched() async {
        sut.isReconnecting = true
        // Suppose GlobalConstants.availableCards indexes map; we just assert finished state exists
        let players = [
            GameData.Player(id: "p1", name: "A", selectedCardIndex: -1),
            GameData.Player(id: "p2", name: "B", selectedCardIndex: -1)
        ]
        let gameData = GameData(players: players, state: .finished)
        
        await mockSocketService.simulateUpdate(gameData: gameData)
        
        if case .finished(let avg) = sut.roomModel.state {
            // With both -1, average should be 0.0 per RoomModel logic
            XCTAssertEqual(avg, 0.0, accuracy: 0.0001)
        } else {
            XCTFail("Expected finished state")
        }
        XCTAssertTrue(sut.isReconnecting, "didUpdateGame should not change reconnecting state")
    }
    
    func testDidFail_DoesNotCrash() {
        let error = SocketError.connectionFailed
        
        sut.didFail(error: error)
        
        // Test passes if no crash occurs
    }
    
    // MARK: - Socket Delegate Tests (didFail / didDisconnect / didReconnect)
    
    func testDidFail_WithEmittingFailed_SetsErrorAndReconnecting() {
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.isReconnecting)
        
        sut.didFail(error: .emittingFailed)
        
        XCTAssertEqual(sut.error, .emittingFailed)
        XCTAssertTrue(sut.isReconnecting)
    }
    
    func testDidFail_WithConnectionFailed_SetsReconnectingOnly() {
        sut.error = nil
        sut.isReconnecting = false
        
        sut.didFail(error: .connectionFailed)
        
        XCTAssertNil(sut.error)
        XCTAssertTrue(sut.isReconnecting)
    }
    
    func testDidDisconnect_SetsReconnecting() {
        sut.isReconnecting = false
        
        sut.didDisconnect()
        
        XCTAssertTrue(sut.isReconnecting)
    }
    
    func testDidReconnect_ClearsReconnectingAndJoinsRoom() {
        sut.isReconnecting = true
        
        sut.didReconnect()
        
        XCTAssertFalse(sut.isReconnecting)
        XCTAssertEqual(mockSocketService.joinRoomCallCount, 1)
        XCTAssertEqual(mockSocketService.lastJoinCreate, false)
        XCTAssertEqual(mockSocketService.lastJoinRoomNumber, "1234")
        XCTAssertEqual(mockSocketService.lastJoinRoomPlayerId, "player1")
        XCTAssertEqual(mockSocketService.lastJoinRoonPlayerName, "John")
    }
    
    // MARK: - Integration Tests
    
    func testCompleteGameFlow() async {
        XCTAssertEqual(sut.roomModel.state, .lobby)
        XCTAssertFalse(sut.showCardSelector)
        
        sut.handleHostAction()
        XCTAssertTrue(sut.showCardSelector)
        XCTAssertEqual(mockSocketService.startGameCallCount, 1)
        
        sut.selectCard(cardIndex: 3)
        XCTAssertEqual(sut.selectedCardIndex, 3)
        XCTAssertEqual(mockSocketService.selectCardCallCount, 1)
        
        sut.handleHostAction()
        XCTAssertEqual(mockSocketService.endGameCallCount, 1)
        
        let gameData = GameData(
            players: [GameData.Player(id: "player1", name: "John", selectedCardIndex: 3)],
            state: .finished
        )
        await mockSocketService.simulateUpdate(gameData: gameData)
        
        XCTAssertFalse(sut.showCardSelector)
        XCTAssertNil(sut.selectedCardIndex)
    }
   
    func testMultiplePlayerUpdate() async {
        let players = [
            GameData.Player(id: "player1", name: "John", selectedCardIndex: 2),
            GameData.Player(id: "player2", name: "Jane", selectedCardIndex: -1),
            GameData.Player(id: "player3", name: "Bob", selectedCardIndex: 5)
        ]
        let gameData = GameData(
            players: players,
            state: .selecting
        )
        
        await mockSocketService.simulateUpdate(gameData: gameData)
        
        XCTAssertEqual(sut.roomModel.players.count, 3)
        if case .selecting(let count, let total) = sut.roomModel.state {
            XCTAssertEqual(count, 2)
            XCTAssertEqual(total, 3)
        } else {
            XCTFail("Expected selecting state")
        }
    }
}

