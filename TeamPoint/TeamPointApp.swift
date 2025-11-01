//
//  TeamPointApp.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI

@main
struct TeamPointApp: App {
    private let socketManager = SocketService()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(socketManager)
        }
    }
}
