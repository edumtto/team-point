//
//  HomeView.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        HStack {
            TextField("", text: .constant(""))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Spacer()
            Button("Send") {
                print("Sent")
            }
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
