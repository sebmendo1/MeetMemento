import SwiftUI

/// A tiny, self-contained UI component with **pure inputs** so it can preview instantly
/// without booting your app, networking, or hitting storage.
struct JournalCard: View {
    // MARK: - Inputs (pure data only)
    let title: String
    let excerpt: String
    let date: Date

    /// Optional actions (no-op by default so previews never depend on app state)
    var onTap: (() -> Void)? = nil
    var onMoreTapped: (() -> Void)? = nil
    
    // MARK: - Environment
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
     
    // MARK: - State
    @State private var isPressed = false

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                header
                Text(excerpt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                footer
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            
            Divider()
                .background(theme.border) // Uses theme border color
            
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .contentShape(Rectangle())
        .onTapGesture { 
            // Add haptic feedback for better user experience
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap?() 
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Subviews
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(type.bodyBold) // Manrope Bold for card headers
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 8)
            MoreButton(action: { onMoreTapped?() })
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .imageScale(.small)
                .foregroundStyle(.secondary)
            Text(date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Journal entry date \(date.formatted(date: .abbreviated, time: .shortened))")
    }

    private var accessibilityLabel: String {
        "Journal card, \(title). Dated \(date.formatted(date: .abbreviated, time: .shortened)). \(excerpt)"
    }
}

// MARK: - Three-dot (More) Button
private struct MoreButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "ellipsis")
                .imageScale(.medium)
                .padding(6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("More options")
        .accessibilityHint("Shows actions for this journal entry")
        .contentShape(Rectangle())
    }
}

// MARK: - Sample Data (for previews & local playgrounds)
extension JournalCard {
    static let sampleTitle = "Morning reflection"
    static let sampleExcerpt = "Gratitude for small wins, 5km run, and intention to ship the journaling UI before wiring the backend."
}

// MARK: - SIDE-CAR PREVIEW HARNESS
// Keep previews in the same file for convenience, or move into `JournalCard+Preview.swift`.
// Import NOTHING from your app target here besides SwiftUI and this view file.
private struct JournalCardHarness: View {
    var body: some View {
        JournalCard(
            title: JournalCard.sampleTitle,
            excerpt: JournalCard.sampleExcerpt,
            date: .now,
            onTap: { /* no-op for harness */ },
            onMoreTapped: { /* present a mock sheet/menu in sandbox if you want */ }
        )
        .previewLayout(.sizeThatFits)
        .frame(maxWidth: .infinity) // allow card to stretch
        .background(Color(uiColor: .systemBackground))
    }
}



#Preview("JournalCard · light") {
    JournalCardHarness()
}


#Preview("JournalCard · long text") {
    JournalCard(
        title: "Weekly review and planning checklist for Q4",
        excerpt: "What went well: shipped UI preview harnesses, stabilized Xcode canvas. What to improve: fewer side effects in initializers, mock services end-to-end. Next: connect Supabase after UI is final.",
        date: .now.addingTimeInterval(-36_00)
    )
    //.previewLayout(.sizeThatFits)
    .padding()
}
