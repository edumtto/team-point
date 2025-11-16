/**
 * Handles all Socket.IO events for the application.
 * @param {Server} io The Socket.IO server instance.
 * @param {Low} db The initialized LowDB instance.
 */
export default function registerSocketHandlers(io, db) {

    /**
     * Reads the state of a room from the LowDB store.
     * @param {string} roomNumber
     * @returns {object | null} Deep copy of the room state or null if not found.
     */
    const getRoomState = (roomNumber) => {
        const roomState = db.data.rooms[roomNumber];
        if (!roomState) return null;
        return JSON.parse(JSON.stringify(roomState));
    };

    // Helper to emit the current state to all in a room
    const emitStateToRoom = (roomNumber) => {
        const state = getRoomState(roomNumber);
        if (state) {
            io.to(roomNumber).emit('updateGame', state);
            console.log(`[${roomNumber}] State updated. Players: ${state.players.length}, State: ${state.state}`);
        }
    };
    
    /**
     * Helper function to remove a player and clean up the room if it becomes empty.
     */
    const removePlayerAndCleanRoom = async (playerId, roomNumber) => {
        if (!roomNumber || !db.data.rooms[roomNumber]) return;

        const roomState = db.data.rooms[roomNumber];

        const initialPlayerCount = roomState.players.length;
        roomState.players = roomState.players.filter(p => p.id !== playerId);
        
        if (roomState.players.length < initialPlayerCount) {
            console.log(`Player ${playerId} removed from room ${roomNumber}.`);
        }

        if (roomState.players.length === 0) {
            delete db.data.rooms[roomNumber];
            console.log(`Room ${roomNumber} is empty and has been deleted.`);
        } else {
            emitStateToRoom(roomNumber);
        }

        await db.write();
    };

    // --- Main Connection Handler ---
    io.on('connection', (socket) => {
        console.log(`User connected: ${socket.id}`);
        
        // Event: "join"
        socket.on('join', async (data, callback) => {
            const { roomNumber, playerId, playerName } = data;
            const player = {id: playerId, name: playerName, selectedCardIndex: -1};

            if (!db.data.rooms[roomNumber]) {
                db.data.rooms[roomNumber] = { players: [player], state: 'lobby' };
                console.log(`Created new room: ${roomNumber}`);
            } else {
                db.data.rooms[roomNumber].players.push(player);
            }
            
            await db.write();

            socket.join(roomNumber);
            callback("success");
            
            socket.data.roomNumber = roomNumber;
            socket.data.playerId = playerId;
            
            emitStateToRoom(roomNumber);
        });
        
        // Event: "startGame"
        socket.on('startGame', async (data) => {
            const { roomNumber } = data;
            const roomState = db.data.rooms[roomNumber];
            if (!roomState) {
                console.log(`Room state not found for room ${roomNumber}.`);
                return;
            }

            roomState.state = 'selecting';
            roomState.players.forEach(p => p.selectedCardIndex = -1);

            await db.write();
            console.log(`Game started in room ${roomNumber}.`);
            emitStateToRoom(roomNumber);
        });
        
        // Event: "leave"
        socket.on('leave', async (data) => {
            const { roomNumber, playerId } = data;
            socket.leave(roomNumber);
            await removePlayerAndCleanRoom(playerId, roomNumber);
            delete socket.data.roomNumber;
            delete socket.data.playerId;
        });
        
        // Event: "selectCard"
        socket.on('selectCard', async (data) => {
            const { roomNumber, playerId, cardIndex } = data;
            const roomState = db.data.rooms[roomNumber];

            if (!roomState || roomState.state !== 'selecting') return;
            
            const player = roomState.players.find(p => p.id === playerId);
            if (player) {
                player.selectedCardIndex = cardIndex >= 0 ? cardIndex : -1;
                await db.write();
                emitStateToRoom(roomNumber);
            }
        });
        
        // Event: "endGame"
        socket.on('endGame', async (data) => {
            const { roomNumber } = data; 
            const roomState = db.data.rooms[roomNumber];
            if (!roomState) {
              console.log(`Room state not found for room ${roomNumber}.`);
              return;
            }
            roomState.state = 'finished';
            await db.write();

            console.log(`Game ended (cards revealed) in room ${roomNumber}.`);
            emitStateToRoom(roomNumber);
        });
        
        // Event: "disconnect"
        socket.on('disconnect', async () => {
            console.log(`User disconnected: ${socket.id}`);
            // const { roomNumber, playerId } = socket.data;
            // if (roomNumber && playerId) {
            //     await removePlayerAndCleanRoom(playerId, roomNumber);
            // }
        });
    });
}