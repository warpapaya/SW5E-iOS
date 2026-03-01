import SwiftUI

/// Section header with small caps-style label and divider.
/// Inspired by Echoveil UI elements and aesthetic.
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Left accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.veilGold)
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
