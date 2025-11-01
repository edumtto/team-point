//
//  HomeView.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI

// MARK: - Reusable Components
struct LogoView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.textWhite.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 50))
                    .foregroundColor(AppTheme.Colors.textWhite)
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

struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.red)
        .cornerRadius(AppTheme.CornerRadius.small)
        .shadow(radius: 5)
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
                TextField("Enter 5-digit room code", text: $roomNumber)
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
                        .padding(.vertical, AppTheme.Spacing.medium)
                        .background(isEnabled ? Color.blue : Color.gray)
                        .cornerRadius(AppTheme.CornerRadius.small)
                }
                .disabled(!isEnabled)
            }
        }
    }
}

struct NamePopupView: View {
    @Binding var userName: String
    @Binding var errorMessage: String?
    @Binding var showError: Bool
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
            
            TextField("Your name", text: $userName)
                .inputFieldStyle()
            
            if showError, let error = errorMessage {
                ErrorBanner(message: error)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
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
        .shadow(color: AppTheme.Shadows.popup, radius: 20)
        .padding(.horizontal, AppTheme.Spacing.xxlarge)
    }
}

struct HomeView: View {
    @EnvironmentObject var socketManager: SocketService
    @StateObject private var viewModel = HomeViewModel(socketService: SocketService())
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Bacwkground gradient
                AppTheme.Colors.primaryGradient
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
                            onJoin: viewModel.validateAndJoinRoom,
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
                
                // Name popup overlay
                if viewModel.showNamePopup {
                    AppTheme.Colors.overlayBackground
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewModel.cancelNameEntry()
                        }
                    
                    NamePopupView(
                        userName: $viewModel.userName,
                        errorMessage: $viewModel.errorMessage,
                        showError: $viewModel.showError,
                        title: viewModel.popupTitle,
                        isContinueEnabled: viewModel.isContinueButtonEnabled,
                        onCancel: viewModel.cancelNameEntry,
                        onContinue: viewModel.confirmAction
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
//            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showNamePopup)
//            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showError)
        }
    }
}

#Preview {
    HomeView()
}
