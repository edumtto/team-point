import express from 'express';
import { createServer } from 'node:http';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { Server } from 'socket.io';

const app = express();
const server = createServer(app);
const io = new Server(server);

const __dirname = dirname(fileURLToPath(import.meta.url));

const globalGameState = {};

// Default card set for the game
const POKER_CARDS = [0, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, '?', 'coffee'];

io.on('connection', (socket) => {
    console.log('a user connected');
    let room = null;
    
    socket.on('leave', () => {
        if (room) {
            socket.leave(room);
            room = null;
        }
    });
    
    socket.on('join', (data) => {
        const roomNumber = data.roomNumber;
        const playerId = data.playerId;
        const playerName = data.playerName;
        
        console.log(playerName + ' joined room: ' + roomNumber);
        room = roomNumber;
        socket.join(roomNumber);
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

server.listen(3000, () => {
    console.log('server running at http://localhost:3000');
});


// socket.disconnect();
