//
//  HomeViewModelTests.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 11/2/25.
//

import XCTest
import Combine
@testable import TeamPoint

@MainActor
final class HomeViewModelTests: XCTestCase {
    var sut: HomeViewModel!
    var mockSocketService: MockSocketService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockSocketService = MockSocketService()
        sut = HomeViewModel(socketService: mockSocketService)
        cancellables = []
    }
    
    override func tearDown() {
        sut = nil
        mockSocketService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertEqual(sut.roomNumber, "")
        XCTAssertEqual(sut.playerName, "")
        XCTAssertFalse(sut.playerId.isEmpty)
        XCTAssertFalse(sut.showNamePopup)
        XCTAssertNil(sut.actionType)
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.navigateToRoom)
    }
    
    func testPlayerIdIsUUID() {
        XCTAssertNotNil(UUID(uuidString: sut.playerId))
    }
    
    func testSocketServiceDelegateIsSet() {
        XCTAssertTrue(mockSocketService.connectionDelegate === sut)
    }
    
    // MARK: - Reconnection Tests
    func testReconnect() {
        sut.reconnect()
        XCTAssertEqual(mockSocketService.establishConnectionCallCount, 1)
    }
    
    // MARK: - Room Number Update Tests
    
    func testUpdateRoomNumberWithValidDigits() {
        sut.updateRoomNumber("12345")
        XCTAssertEqual(sut.roomNumber, "12345")
    }
    
    func testUpdateRoomNumberFiltersNonNumericCharacters() {
        sut.updateRoomNumber("123abc456")
        XCTAssertEqual(sut.roomNumber, "12345")
    }
    
    func testUpdateRoomNumberLimitsToFiveDigits() {
        sut.updateRoomNumber("123456789")
        XCTAssertEqual(sut.roomNumber, "12345")
    }
    
    func testUpdateRoomNumberWithMixedCharacters() {
        sut.updateRoomNumber("1a2b3c4d5e6f")
        XCTAssertEqual(sut.roomNumber, "12345")
    }
    
    func testUpdateRoomNumberWithEmptyString() {
        sut.roomNumber = "12345"
        sut.updateRoomNumber("")
        XCTAssertEqual(sut.roomNumber, "")
    }
    
    func testUpdateRoomNumberWithSpecialCharacters() {
        sut.updateRoomNumber("!@#$%12345^&*()")
        XCTAssertEqual(sut.roomNumber, "12345")
    }
    
    // MARK: - Join Room Tests
    
    func testStartJoinRoom() {
        sut.startJoinRoom()
        
        XCTAssertEqual(sut.actionType, .join)
        XCTAssertTrue(sut.showNamePopup)
    }
    
    func testIsJoinButtonEnabledWithValidRoomNumber() {
        sut.updateRoomNumber("12345")
        XCTAssertTrue(sut.isJoinButtonEnabled)
    }
    
    func testIsJoinButtonDisabledWithInvalidRoomNumber() {
        sut.updateRoomNumber("1234")
        XCTAssertFalse(sut.isJoinButtonEnabled)
    }
    
    func testIsJoinButtonDisabledWithEmptyRoomNumber() {
        XCTAssertFalse(sut.isJoinButtonEnabled)
    }
    
    // MARK: - Create Room Tests
    
    func testStartCreateRoom() {
        sut.startCreateRoom()
        
        XCTAssertEqual(sut.actionType, .create)
        XCTAssertTrue(sut.showNamePopup)
    }
    
    func testIsUserHostWhenCreating() {
        sut.startCreateRoom()
        XCTAssertTrue(sut.isUserHost)
    }
    
    func testIsUserHostWhenJoining() {
        sut.startJoinRoom()
        XCTAssertFalse(sut.isUserHost)
    }
    
    func testIsUserHostWhenNoAction() {
        XCTAssertFalse(sut.isUserHost)
    }
    
    // MARK: - Cancel Name Entry Tests
    
    func testCancelNameEntry() {
        sut.showNamePopup = true
        sut.playerName = "Test Player"
        
        sut.cancelNameEntry()
        
        XCTAssertFalse(sut.showNamePopup)
        XCTAssertEqual(sut.playerName, "")
    }
    
    // MARK: - Continue Button Tests
    
    func testIsContinueButtonEnabledWithValidName() {
        sut.playerName = "John"
        XCTAssertTrue(sut.isContinueButtonEnabled)
    }
    
    func testIsContinueButtonDisabledWithEmptyName() {
        sut.playerName = ""
        XCTAssertFalse(sut.isContinueButtonEnabled)
    }
    
    func testIsContinueButtonDisabledWithWhitespaceName() {
        sut.playerName = "   "
        XCTAssertFalse(sut.isContinueButtonEnabled)
    }
    
    func testIsContinueButtonEnabledWithNameAndWhitespace() {
        sut.playerName = "  John  "
        XCTAssertTrue(sut.isContinueButtonEnabled)
    }
    
    // MARK: - Popup Title Tests
    
    func testPopupTitleForJoin() {
        sut.actionType = .join
        XCTAssertEqual(sut.popupTitle, "Join Room")
    }
    
    func testPopupTitleForCreate() {
        sut.actionType = .create
        XCTAssertEqual(sut.popupTitle, "Create Room")
    }
    
    // MARK: - Confirm Action Tests
    
    func testConfirmActionForJoinRoom() {
        sut.actionType = .join
        sut.roomNumber = "12345"
        sut.playerName = "John"
        let playerId = sut.playerId
        
        sut.confirmAction()
        
        XCTAssertTrue(sut.isLoading)
        XCTAssertEqual(mockSocketService.joinRoomCallCount, 1)
        XCTAssertEqual(mockSocketService.lastJoinRoomNumber, "12345")
        XCTAssertEqual(mockSocketService.lastJoinRoomPlayerId, playerId)
        XCTAssertEqual(mockSocketService.lastJoinRoonPlayerName, "John")
    }
    
    func testConfirmActionForCreateRoom() {
        sut.actionType = .create
        sut.playerName = "Jane"
        let playerId = sut.playerId
        
        sut.confirmAction()
        
        XCTAssertTrue(sut.isLoading)
        XCTAssertEqual(mockSocketService.joinRoomCallCount, 1)
        XCTAssertEqual(mockSocketService.lastJoinRoomPlayerId, playerId)
        XCTAssertEqual(mockSocketService.lastJoinRoonPlayerName, "Jane")
        
        // Verify room number was generated and is valid
        XCTAssertNotNil(mockSocketService.lastJoinRoomNumber)
        XCTAssertEqual(mockSocketService.lastJoinRoomNumber?.count, 5)
        if let roomNum = mockSocketService.lastJoinRoomNumber,
           let numValue = Int(roomNum) {
            XCTAssertGreaterThanOrEqual(numValue, 10000)
            XCTAssertLessThanOrEqual(numValue, 99999)
        } else {
            XCTFail("Generated room number should be valid")
        }
    }
    
    func testConfirmActionUpdatesRoomNumberForCreateRoom() {
        sut.actionType = .create
        sut.playerName = "Jane"
        
        sut.confirmAction()
        
        // Room number should be set to the generated value
        XCTAssertEqual(sut.roomNumber.count, 5)
        XCTAssertEqual(sut.roomNumber, mockSocketService.lastJoinRoomNumber)
    }
    
    // MARK: - Socket Delegate Tests
    
    func testDidJoinRoomSuccess() {
        sut.isLoading = true
        sut.showNamePopup = true
        
        mockSocketService.simulateSuccess()
        
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.navigateToRoom)
        XCTAssertFalse(sut.showNamePopup)
    }
    
    func testDidFailWithError() {
        sut.isLoading = true
        let expectedError = SocketError.connectionFailed
        
        mockSocketService.simulateError(expectedError)
        
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.error, expectedError)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteJoinRoomFlow() {
        // User enters room number
        sut.updateRoomNumber("54321")
        XCTAssertTrue(sut.isJoinButtonEnabled)
        
        // User starts join process
        sut.startJoinRoom()
        XCTAssertTrue(sut.showNamePopup)
        XCTAssertEqual(sut.actionType, .join)
        
        // User enters name
        sut.playerName = "Alice"
        XCTAssertTrue(sut.isContinueButtonEnabled)
        
        // User confirms
        sut.confirmAction()
        XCTAssertTrue(sut.isLoading)
        XCTAssertEqual(mockSocketService.joinRoomCallCount, 1)
        
        // Socket succeeds
        mockSocketService.simulateSuccess()
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.navigateToRoom)
        XCTAssertFalse(sut.showNamePopup)
    }
    
    func testCompleteCreateRoomFlow() {
        // User starts create process
        sut.startCreateRoom()
        XCTAssertTrue(sut.showNamePopup)
        XCTAssertEqual(sut.actionType, .create)
        XCTAssertTrue(sut.isUserHost)
        
        // User enters name
        sut.playerName = "Bob"
        XCTAssertTrue(sut.isContinueButtonEnabled)
        
        // User confirms
        sut.confirmAction()
        XCTAssertTrue(sut.isLoading)
        XCTAssertEqual(mockSocketService.joinRoomCallCount, 1)
        XCTAssertFalse(sut.roomNumber.isEmpty)
        
        // Socket succeeds
        mockSocketService.simulateSuccess()
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.navigateToRoom)
    }
    
    func testCancelFlowResetsState() {
        sut.startJoinRoom()
        sut.playerName = "Charlie"
        
        sut.cancelNameEntry()
        
        XCTAssertFalse(sut.showNamePopup)
        XCTAssertEqual(sut.playerName, "")
        XCTAssertEqual(mockSocketService.joinRoomCallCount, 0)
    }
    
    // MARK: - Published Properties Tests
    
    func testRoomNumberPublisher() {
        let expectation = XCTestExpectation(description: "Room number published")
        var receivedValues: [String] = []
        
        sut.$roomNumber
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        sut.updateRoomNumber("12345")
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, ["12345"])
    }
    
    func testNavigateToRoomPublisher() {
        let expectation = XCTestExpectation(description: "Navigate to room published")
        
        sut.$navigateToRoom
            .dropFirst()
            .sink { value in
                if value {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockSocketService.simulateSuccess()
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(sut.navigateToRoom)
    }
}
