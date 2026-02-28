import SwiftUI

/// Section header with small caps-style label and divider.
/// Inspired by Aurebesh-inspired UI elements from Star Wars interfaces.
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Left accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.hologramBlue)
                    .frame(width: 4, height: 20)
                
                Text(title.uppercased())
                    .font(.headline)
                    .fontWeight(.semibold)
                    .kerning(1.5) // Small caps effect via tracking
                    .foregroundStyle(Color.lightText)
            }
            
            Divider()
                .overlay(Color.borderSubtle)
        }
    }
}

// MARK: - Preview Provider
#Preview("Section Header") {
    VStack(alignment: .leading, spacing: 16) {
        SectionHeader(title: "Character Vitals")
        
        SectionHeader(title: "Ability Scores")
        
        SectionHeader(title: "Force Powers")
    }
    .padding()
}
