import SwiftUI

// MARK: - Template Picker View

/// Bottom-sheet style view for selecting a campaign template.
/// Shows 4 cards: Outer Rim Job, Jedi Academy, Rebel Cell, Sandbox.
struct TemplatePickerView: View {
    let onSelect: (CampaignTemplate) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Choose your adventure")
                        .font(.subheadline)
                        .foregroundColor(.mutedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    ForEach(CampaignTemplate.all) { template in
                        TemplateCard(template: template) {
                            onSelect(template)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color.spacePrimary.ignoresSafeArea())
            .navigationTitle("New Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                        .foregroundColor(.hologramBlue)
                }
            }
        }
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: CampaignTemplate
    let onTap: () -> Void

    @State private var isPressed = false

    var accentGradient: LinearGradient {
        switch template.accentColor {
        case .blue:   return LinearGradient(colors: [.hologramBlue, .holoBlueSubtle], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .purple: return LinearGradient(colors: [Color(red: 0.6, green: 0.2, blue: 0.9), Color(red: 0.3, green: 0.1, blue: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .red:    return LinearGradient(colors: [.siithRed, Color(red: 0.5, green: 0.1, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gold:   return LinearGradient(colors: [.techOrange, Color(red: 0.6, green: 0.4, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var accentForeground: Color {
        switch template.accentColor {
        case .blue:   return .hologramBlue
        case .purple: return Color(red: 0.7, green: 0.5, blue: 1.0)
        case .red:    return .siithRed
        case .gold:   return .techOrange
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                HStack(spacing: 12) {
                    // Icon bubble
                    ZStack {
                        Circle()
                            .fill(accentGradient)
                            .frame(width: 48, height: 48)
                        Image(systemName: template.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.lightText)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.lightText)

                        // Era badge
                        Text(template.era)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(accentForeground.opacity(0.18))
                            .foregroundColor(accentForeground)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    // Difficulty stars
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Difficulty")
                            .font(.caption2)
                            .foregroundColor(.mutedText)
                        HStack(spacing: 2) {
                            ForEach(1...4, id: \.self) { i in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(i <= template.difficulty.stars ? accentForeground : .mutedText.opacity(0.4))
                            }
                        }
                        Text(template.difficulty.rawValue)
                            .font(.caption2)
                            .foregroundColor(.mutedText)
                    }
                }

                // Description
                Text(template.description)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.78, green: 0.84, blue: 0.9))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                // Start button
                HStack {
                    Spacer()
                    Label("Start", systemImage: "play.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.lightText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(accentGradient)
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .background(Color.spaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(accentForeground.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: accentForeground.opacity(isPressed ? 0.4 : 0.15), radius: isPressed ? 12 : 6, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

#Preview("Template Picker") {
    TemplatePickerView(onSelect: { _ in }, onDismiss: {})
        .preferredColorScheme(.dark)
}
