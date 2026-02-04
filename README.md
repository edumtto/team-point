# TeamPoint: Planning Poker Made Simple
TeamPoint is a simple, real-time application for agile teams to estimate user stories using the Planning Poker technique.

## App Screenshot

<img width="300" alt="App Screenshot" src="https://github.com/user-attachments/assets/887392c5-05bd-4297-908d-6c6faa78c4f2" />

## 🚀 Quick Start
TeamPoint requires running both the client app (iOS/macOS) and a Node.js server.

### 🖥️ Server (Node.js/Socket.io)
1. Navigate to the SocketIOServer directory.

2. Install dependencies:

```bash
npm install express socket.io
```
3. Start the server:

```bash
node index.js
```

### 📱 Client (Swift/Xcode)
1. Open TeamPoint.xcodeproj in Xcode.

2. Build and run the app in the simulator or on a device.

Note: For physical device builds, set ```GlobalConstants.baseURL``` to your server IP.

## 🛠️ Tech Stack
Client: Swift / Xcode

Server: Node.js, Express, Socket.io
