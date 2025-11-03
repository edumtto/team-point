import express from 'express';
import { createServer } from 'node:http';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { Server } from 'socket.io';

/**
 * Represents the global state for the Planning Poker game.
 * Key: roomNumber (String)
 * Value: {
 *     players: Array<{id: String, name: String, selectedCardIndex: Int | null}>,
 *     state: 'lobby' | 'selecting' | 'finished'
 * }
 */
const globalGameState = {};

// --- Server Setup ---
const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
    cors: {
        origin: "http://localhost:3000", // Allow connection from the same origin (for testing)
        methods: ["GET", "POST"]
    }
});

const PORT = 3000;

const getRoomState = (roomNumber) => {
    // Return a deep copy to prevent external modification
    return JSON.parse(JSON.stringify(globalGameState[roomNumber]));
};

// --- Socket.IO Event Handlers ---
io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);
    
    // Helper to emit the current state to all in a room
    const emitStateToRoom = (roomNumber) => {
        const state = getRoomState(roomNumber);
        io.to(roomNumber).emit('updateGame', state);
        console.log(`[${roomNumber}] State updated. Players: ${state.players.length}, State: ${state.state}`);
    };
    
    /**
     * Helper function to remove a player and clean up the room if it becomes empty.
     * @param {string} playerId The ID of the socket/player leaving.
     * @param {string} roomNumber The code of the room to clean up.
     */
    const removePlayerAndCleanRoom = (playerId, roomNumber) => {
        if (!roomNumber || !globalGameState[roomNumber]) return;

        const roomState = globalGameState[roomNumber];

        const initialPlayerCount = roomState.players.length;
        roomState.players = roomState.players.filter(p => p.id !== playerId);
        
        if (roomState.players.length < initialPlayerCount) {
            console.log(`Player ${playerId} removed from room ${roomNumber}.`);
        }

        // Check if the room is now empty
        if (roomState.players.length === 0) {
            delete globalGameState[roomNumber];
            console.log(`Room ${roomNumber} is empty and has been deleted.`);
        } else {
            // If the room still has players, broadcast the state update
            emitStateToRoom(roomNumber);
        }
    };
    
    /**
    * Event: "join"
    * Params: {
    *    roomNumber: String,
    *    playerId: String,
    *    playerName: String
    *}
    * Action: Player joins a specific room namespace.
    */
    socket.on('join', (data) => {
        const roomNumber = data.roomNumber;
        const playerId = data.playerId;
        const playerName = data.playerName;
        
        const player = {id: playerId, name: playerName, selectedCardIndex: -1}
        
        if (!globalGameState[roomNumber]) {
            globalGameState[roomNumber] = {
                players: [player],
                state: 'lobby'
            };
            console.log(`Created new room: ${roomNumber}`);
        } else {
            globalGameState[roomNumber].players.push(player)
        }
        
        socket.join(roomNumber);
        console.log(playerName + ' joined room: ' + roomNumber);
        
        // Store client information for future disconect event
        socket.data.roomNumber = roomNumber;
        socket.data.playerId = playerId;
        
        
        const roomState = getRoomState(roomNumber);
        io.to(roomNumber).emit('updateGame', roomState);
        console.log(`[${roomNumber}] State updated. Players: ${roomState.players.length}, State: ${roomState.state}`);
    });
    
    /**
     * Event: "startGame"
     * Params: {
     *    roomNumber: String,
     *}
     * Action: Starts a new round. Clears previous selections, sets state to 'selecting', sets reveal to false.
     * Response: Broadcasts the updated global state to the room.
     */
    socket.on('startGame', (data) => {
        const roomNumber = data.roomNumber;
        if (!roomNumber || !globalGameState[roomNumber]) return;

        const roomState = globalGameState[roomNumber];

        roomState.state = 'selecting';

        // Clear previous selections
        roomState.players.forEach(p => p.selectedCardIndex = -1);

        console.log(`Game started in room ${roomNumber}.`);
        emitStateToRoom(roomNumber);
    });
    
    /**
    * Event: "leave"
     * Params: {
     *    roomNumber: String,
     *    playerId: String
     *}
    * Action: Player explicitly leaves the room.
    * Logic: Removes the player from the state and deletes the room if it becomes empty.
    */
    socket.on('leave', (data) => {
        const roomNumber = data.roomNumber;
        const playerId = data.playerId;
        
        socket.leave(roomNumber);
        removePlayerAndCleanRoom(playerId, roomNumber);
        
        delete socket.data.roomNumber;
        delete socket.data.playerId;
    });
    
    /**
     * Event: "selectCard"
     * Params: {
     *    roomNumber: String,
     *    playerId: String,
     *    cardIndex: Int
     *}
     * Action: Player selects a card. Updates the player's selectedCardIndex.
     * Response: Broadcasts the updated global state to the room.
     */
    socket.on('selectCard', (data) => {
        const roomNumber = data.roomNumber;
        const playerId = data.playerId;
        const cardIndex = data.cardIndex;
        
        const roomState = globalGameState[roomNumber];
        const player = roomState.players.find(p => p.id === playerId);
        
        if (player && roomState.state === 'selecting') {
            // Ensure cardIndex is valid for the card array
            if (cardIndex >= 0) {
                player.selectedCardIndex = cardIndex;
                console.log(`Player ${player.name} selected card index ${cardIndex} in room ${roomNumber}`);
                emitStateToRoom(roomNumber);
            } else {
                 // Allow deselection (e.g., clicking the selected card again)
                player.selectedCardIndex = -1;
                console.log(`Player ${player.name} deselected card in room ${roomNumber}`);
                emitStateToRoom(roomNumber);
            }
        }
    });
    
    /**
     * Event: "endGame"
     * Action: Ends the current game.
     * Response: Broadcasts the updated global state to the room.
     */
    socket.on('endGame', (data) => {
        const roomNumber = socket.data.roomNumber;
        if (!globalGameState[roomNumber]) return;

        const roomState = globalGameState[roomNumber];

        roomState.state = 'finished';

        console.log(`Game ended (cards revealed) in room ${roomNumber}.`);
        emitStateToRoom(roomNumber);
    });
    
    /**
     * Event: "disconect"
     * Action: Disconects client.
     * Response: Broadcasts the updated global state to the room.
     */
    socket.on('disconnect', () => {
        const roomCode = socket.data.roomCode;
        const playerId = socket.data.playerId;
        
        console.log(`User disconnected: ${socket.id}`);
        
        if (roomCode && playerId) {
            // Remove the disconnected player from the game state and clean up the room
            // Note: In a production environment, we might wait a few seconds before removing the player
            // to allow for brief network disruptions (reconnection logic).
            console.log(`Handling disconnect for player ${playerId} in room ${roomCode}...`);
            removePlayerAndCleanRoom(playerId, roomCode);
        }
    });
    
});

// --- Start Server ---
httpServer.listen(PORT, () => {
    console.log(`🚀 Socket.IO server running at http://localhost:${PORT}`);
});
