//
//  HomeView.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI

struct HomeView: View {
    let socketManager = SocketIOManager()
    @State private var textInput: String = ""
    
    var body: some View {
        HStack {
            TextField("", text: $textInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Spacer()
            Button("Send") {
                print("Sent")
                socketManager.establishConnection()
                socketManager.sendMessage(sender: "Edu", text: textInput)
            }
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
