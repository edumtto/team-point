//
//  RoomView.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/29/25.
//

import SwiftUI

// MARK: - Reusable Components
struct RoomHeaderView: View {
    let roomNumber: String
    let roomState: RoomModel.State
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: "door.left.hand.open")
                    .font(.title3)
                Text("Room")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(roomNumber)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Text(roomState.description)
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.cardBackground)
        .shadow(color: AppTheme.Shadows.card, radius: 5, y: 2)
    }
}

struct PlayerCardView: View {
    let player: RoomModel.Player
    @Binding var roomState: RoomModel.State
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Card
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(player.hasVoted ?
                          LinearGradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing))
                    .frame(width: 60, height: 90)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .stroke(player.hasVoted ? Color.white.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                
                switch roomState {
                case .lobby:
                    Text("")
                case .selecting(_, _):
                    if player.hasVoted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "hourglass")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                case .finished:
                    if let cardValue = player.cardValue {
                        Text(String(cardValue))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "xmark")
                            .font(.default)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Player name
            Text(player.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1)
                .frame(width: 70)
        }
    }
}

struct PlayersGridView: View {
    let players: [RoomModel.Player]
    @Binding var roomState: RoomModel.State
    
    let columns = [
        GridItem(.adaptive(minimum: 80), spacing: AppTheme.Spacing.large)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.large) {
                ForEach(players) { player in
                    PlayerCardView(player: player, roomState: $roomState)
                }
            }
            .padding()
        }
    }
}

struct HostControlButton: View {
    @Binding var roomState: RoomModel.State
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: roomState.hostButtonIcon)
                    .font(.headline)
                Text(roomState.hostButtonTitle)
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.teal.opacity(0.8), Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(color: AppTheme.Shadows.card, radius: 5, y: 2)
        }
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.vertical, AppTheme.Spacing.small)
    }
}

struct SelectableCard: View {
    let value: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isSelected ?
                          AppTheme.Colors.buttonGradient :
                            LinearGradient(colors: [Color.white, Color.white],
                                           startPoint: .top,
                                           endPoint: .bottom))
                    .frame(width: 70, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: isSelected ? Color.blue.opacity(0.4) : AppTheme.Shadows.card,
                            radius: isSelected ? 8 : 4,
                            y: isSelected ? 4 : 2)
                
                Text("\(value)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .offset(y: isSelected ? -10 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CardSelectorView: View {
    @Binding var selectedCardIndex: Int?
    let availableCards: [Int]
    let onSelect: (Int) -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Text("Select a card")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.large) {
                    ForEach(availableCards.enumerated(), id: \.offset) { index, cardValue in
                        SelectableCard(
                            value: cardValue,
                            isSelected: selectedCardIndex == index,
                            onTap: { onSelect(index) }
                        )
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.vertical, AppTheme.Spacing.medium)
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Colors.cardBackground)
        .shadow(color: AppTheme.Shadows.card, radius: 5, y: -2)
    }
}

// MARK: - Main Room View
struct RoomView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: RoomViewModel
    
    init(roomNumber: String, playerId: String, playerName: String, isHost: Bool) {
        _viewModel = StateObject(
            wrappedValue:
                RoomViewModel(
                    roomNumber: roomNumber,
                    playerId: playerId,
                    playerName: playerName,
                    isHost: isHost,
                    socketService: SocketService.shared
                )
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            RoomHeaderView(
                roomNumber: viewModel.roomNumber,
                roomState: viewModel.roomModel.state
            )
            
            // Players Grid (Main Area)
            PlayersGridView(
                players: viewModel.roomModel.players,
                roomState: $viewModel.roomModel.state
            )
            
            // Host Control Button (Only visible to host)
            if viewModel.isHost {
                HostControlButton(
                    roomState: $viewModel.roomModel.state,
                    onTap: viewModel.handleHostAction
                )
            }
            
            // Card Selector (Bottom)
            if viewModel.showCardSelector {
                CardSelectorView(
                    selectedCardIndex: $viewModel.selectedCardIndex,
                    availableCards: GlobalConstants.availableCards,
                    onSelect: viewModel.selectCard
                )
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        RoomView(roomNumber: "12345", playerName: "James", isHost: true)
    }
}
