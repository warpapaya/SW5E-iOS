import SwiftUI

// MARK: - ScrollView Shows Indicators View

/// A view that wraps content in a ScrollView with indicators shown.
struct ScrollViewShowsIndicators<Content: View>: View {
    let axis: Axis.Set
    let content: () -> Content

    init(_ axis: Axis.Set = .vertical, @ViewBuilder content: @escaping () -> Content) {
        self.axis = axis
        self.content = content
    }

    var body: some View {
        ScrollView(axis, showsIndicators: true) {
            content()
        }
    }
}

// MARK: - Scroll Position Preference Key

struct ScrollPositionPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}
