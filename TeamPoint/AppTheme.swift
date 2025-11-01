//
//  AppTheme.swift
//  TeamPoint
//
//  Created by Eduardo Motta de Oliveira on 10/31/25.
//

import SwiftUI

// MARK: - Theme
struct AppTheme {
    // Colors
    struct Colors {
        static let primaryGradient = LinearGradient(
            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let buttonGradient = LinearGradient(
            colors: [Color.purple, Color.blue],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let cardBackground = Color(.systemBackground)
        static let inputBackground = Color(.systemGray6)
        static let overlayBackground = Color.black.opacity(0.4)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textWhite = Color.white
    }
    
    // Spacing
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
        static let xlarge: CGFloat = 24
        static let xxlarge: CGFloat = 40
    }
    
    // Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
    }
    
    // Shadows
    struct Shadows {
        static let card = Color.black.opacity(0.1)
        static let popup = Color.black.opacity(0.2)
    }
}

// MARK: - Custom View Styles
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(AppTheme.Colors.textWhite)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isEnabled ?
                    AnyView(AppTheme.Colors.buttonGradient) :
                    AnyView(Color.gray)
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(AppTheme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(AppTheme.CornerRadius.small)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct InputFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding()
            .background(AppTheme.Colors.inputBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
    }
}

extension View {
    func inputFieldStyle() -> some View {
        modifier(InputFieldStyle())
    }
}
