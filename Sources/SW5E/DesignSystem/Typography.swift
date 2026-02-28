import SwiftUI

/// Star Wars-themed typography extensions.
/// Uses SF Pro Display as base, with SF Mono for data readouts when available.
extension Font {
    // MARK: - Title Typography

    /// Main title font — inspired by Star Wars opening crawl
    static var starWarsTitle: Font {
        .largeTitle.weight(.bold)
    }

    // MARK: - Display Typography

    /// Hologram display headline — monospaced, tech feel
    static var holoDisplay: Font {
        .headline.weight(.semibold).monospacedDigit()
    }

    // MARK: - Data Readout Typography

    /// Caption-level data display — strictly monospaced for numbers
    static var dataReadout: Font {
        .caption.monospacedDigit()
    }

    // MARK: - Body Typography

    /// Standard body text for narrative and descriptions
    static var bodyText: Font {
        .body.weight(.regular)
    }

    /// Small label text for badges and tags
    static var labelSmall: Font {
        .caption2.weight(.medium)
    }
}

// MARK: - Preview Provider
#Preview("Typography") {
    VStack(alignment: .leading, spacing: 24) {
        Text("Star Wars Title")
            .font(.starWarsTitle)
            .tracking(2)

        Text("Hologram Display")
            .font(.holoDisplay)

        Text("Data Readout")
            .font(.dataReadout)

        Text("Body text for narrative descriptions and longer passages.")
            .font(.bodyText)

        Text("Label Badge")
            .font(.labelSmall)
    }
    .foregroundStyle(Color.lightText)
    .background(Color.spaceCard)
    .padding()
}
