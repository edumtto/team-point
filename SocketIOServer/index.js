import express from 'express';
import { createServer } from 'node:http';
import { Server } from 'socket.io';

import { Low } from 'lowdb';
import { JSONFile } from 'lowdb/node';

import registerSocketHandlers from './socketHandlers.js';

// --- Database Setup ---
const file = 'db.json';
const adapter = new JSONFile(file);

/**
 * The 'rooms' property in db.data will now hold your game state, e.g.:
 * db.data.rooms = {
 *    '1234': {
 *        players: Array<{id: String, name: String, selectedCardIndex: Int | null}>,
 *        state: 'lobby' | 'selecting' | 'finished'
 *   },
 *    // ... other rooms
 * }
 */

const db = new Low(adapter, { rooms: {} });

// --- Server Setup ---
const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
    cors: {
        origin: "http://localhost:3000",
        methods: ["GET", "POST"]
    }
});

const PORT = 3000;

/**
 * Reads the state of a room from the LowDB store.
 * @param {string} roomNumber
 * @returns {object | null} Deep copy of the room state or null if not found.
 */
const getRoomState = (roomNumber) => {
    const roomState = db.data.rooms[roomNumber];
    if (!roomState) return null;
    // Return a deep copy to prevent external modification
    return JSON.parse(JSON.stringify(roomState));
};

// --- Start Server ---
async function main() {
    // 1. Read the initial database file
    await db.read();
    
    // 2. Set default structure if file was empty
    db.data = db.data || { rooms: {} };
    
    // 3. Write initial state (optional, but ensures db.json file exists)
    await db.write();

    // 4. REGISTER THE SOCKET HANDLERS
    registerSocketHandlers(io, db);

    httpServer.listen(PORT, () => {
        console.log(`🚀 Socket.IO server running at http://localhost:${PORT}`);
    });
}

main(); // Start the server after db initialization