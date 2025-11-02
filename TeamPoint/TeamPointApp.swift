//
//  TeamPointApp.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI

private let socketManager = SocketService()

@main
struct TeamPointApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(socketManager)
        }
    }
}
