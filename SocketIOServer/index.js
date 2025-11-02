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

// Default card set for the game
const POKER_CARDS = [0, 1, 2, 3, 5, 8, 13, 20, 40, 100];

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
    let room = null; // TODO: Remove line
    console.log(`User connected: ${socket.id}`);
    
    // Helper to emit the current state to all in a room
    const emitStateToRoom = (roomNumber) => {
        const state = getRoomState(roomNumber);
        io.to(roomNumber).emit('updateGame', state);
        console.log(`[${roomNumber}] State updated. Players: ${state.players.length}, State: ${state.state}`);
    };
    
    /**
    * Event: "join"
    * Params: {
    *    roomNumber: String,
    *    isNewRoom: Bool,
    *    playerId: String,
    *    playerName: String
    *}
    * Action: User joins a specific room namespace.
    */
    socket.on('join', (data) => {
        const roomNumber = data.roomNumber;
//        const isNewRoom = data.isNewRoom;
        const playerId = data.playerId;
        const playerName = data.playerName;
        
        
        
        if (!globalGameState[roomNumber]) {
            globalGameState[roomNumber] = {
                players: [],
                state: 'lobby'
            };
            console.log(`Created new room: ${roomNumber}`);
        }
        
        socket.join(roomNumber);
        socket.data.roomNumber = roomNumber;
        console.log(playerName + ' joined room: ' + roomNumber);
        
        socket.emit('updateGame', getRoomState(roomNumber));
    });
    
    socket.on('leave', () => {
        if (room) {
            socket.leave(room);
            room = null;
        }
    });
    
    socket.on('disconnect', () => {
        if (room) {
            socket.leave(room);
        }
        console.log('user disconnected');
    });
    
    socket.on('selectCard', (data) => {
        const playerId = data.playerId;
        const cardId = data.cardId;
        
        console.log(`Player ID: ${playerId}`);
        console.log(`Card ID: ${cardId}`);
        //    console.log('data: ' + data);
        //    if (room) {
        //      io.to(room).emit('chat message', msg);
        //    }
    });
});

// --- Start Server ---
httpServer.listen(PORT, () => {
    console.log(`🚀 Socket.IO server running at http://localhost:${PORT}`);
});


// socket.disconnect();
