//
//  HomeView.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI

enum HomeViewField: Hashable {
    case roomNumber
    case playerName
}

// MARK: - Reusable Components
struct LogoView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            ZStack {
                Image(.pokerCards)
            }
            
            Text("TeamPoint")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.Colors.textWhite)
            
            Text("Planning Poker Made Simple")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textWhite.opacity(0.9))
        }
    }
}

struct RoomInputSection: View {
    @Binding var roomNumber: String
    let onJoin: () -> Void
    let isEnabled: Bool
    let onRoomNumberChange: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Room Number")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            HStack {
                TextField("Enter room code", text: $roomNumber)
                    .keyboardType(.numberPad)
                    .inputFieldStyle()
                    .onChange(of: roomNumber) { oldValue, newValue in
                        onRoomNumberChange(newValue)
                    }
                
                Button(action: onJoin) {
                    Text("Join Room")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.textWhite)
                        .padding(.horizontal, AppTheme.Spacing.large)
                        .padding(.vertical)
                        .background(isEnabled ? Color.blue : Color.gray)
                        .cornerRadius(AppTheme.CornerRadius.small)
                }
                .disabled(!isEnabled)
            }
        }
    }
}

struct NamePopupView: View {
    @Binding var playerName: String
    @FocusState.Binding var focusedField: HomeViewField?
    let title: String
    let isContinueEnabled: Bool
    let onCancel: () -> Void
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Enter your name to continue")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            TextField("Your name", text: $playerName)
                .inputFieldStyle()
                .focused($focusedField, equals: .playerName)
            
            HStack(spacing: AppTheme.Spacing.medium) {
                Button(action: onCancel) {
                    Text("Cancel")
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(action: onContinue) {
                    Text("Continue")
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: isContinueEnabled))
                .disabled(!isContinueEnabled)
            }
        }
        .padding(AppTheme.Spacing.xlarge)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .stroke(.white, lineWidth: 0.5)
        )
        .shadow(color: AppTheme.Shadows.popup, radius: 20)
        .padding(.horizontal, AppTheme.Spacing.xxlarge)
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4) // Semi-transparent background
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5) // Make the spinner larger
                
                Text("Loading...")
                    .foregroundColor(.white)
                    .padding(.top, 10)
            }
            .padding(20)
            .background(Color.gray.opacity(0.8))
            .cornerRadius(15)
        }
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel(socketService: SocketService.shared)
    @FocusState private var focusedField: HomeViewField?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Bacwkground gradient
                AppTheme.Colors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.Spacing.xxlarge) {
                    Spacer()
                    
                    // Logo
                    LogoView()
                    
                    Spacer()
                    
                    // Main content card
                    VStack(spacing: AppTheme.Spacing.xlarge) {
                        // Room number input
                        RoomInputSection(
                            roomNumber: $viewModel.roomNumber,
                            onJoin: viewModel.startJoinRoom,
                            isEnabled: viewModel.isJoinButtonEnabled,
                            onRoomNumberChange: viewModel.updateRoomNumber
                        )
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(AppTheme.Colors.textSecondary.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.horizontal, AppTheme.Spacing.small)
                            
                            Rectangle()
                                .fill(AppTheme.Colors.textSecondary.opacity(0.3))
                                .frame(height: 1)
                        }
                        
                        // Create room button
                        Button(action: viewModel.startCreateRoom) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create New Room")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(AppTheme.Spacing.xlarge)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.large)
                    .shadow(color: AppTheme.Shadows.card, radius: 20, y: 10)
                    .padding(.horizontal, AppTheme.Spacing.xlarge)
                    
                    Spacer()
                }
                
                // Popup overlay
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.showNamePopup {
                    AppTheme.Colors.overlayBackground
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewModel.cancelNameEntry()
                        }
                    
                    NamePopupView(
                        playerName: $viewModel.playerName,
                        focusedField: $focusedField,
                        title: viewModel.popupTitle,
                        isContinueEnabled: viewModel.isContinueButtonEnabled,
                        onCancel: viewModel.cancelNameEntry,
                        onContinue: viewModel.confirmAction
                    )
                    .transition(.scale.combined(with: .opacity))
                    .task(id: viewModel.showNamePopup) {
                        focusedField = viewModel.showNamePopup ? .playerName : nil
                    }
                }
            }
            .navigationDestination(isPresented: $viewModel.navigateToRoom) {
                RoomView(
                    roomNumber: viewModel.roomNumber,
                    playerId: viewModel.playerId,
                    playerName: viewModel.playerName,
                    isHost: viewModel.isUserHost
                )
            }
            
            .alert(item: $viewModel.error) { (error: SocketError) in
                    Alert(
                        title: Text("Join Error"),
                        message: Text(error.localizedDescription),
                        dismissButton: .default(Text("Try again"), action: {
                            viewModel.reconnect()
                        })
                    )
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showNamePopup)
    }
}

#Preview {
    HomeView()
}
