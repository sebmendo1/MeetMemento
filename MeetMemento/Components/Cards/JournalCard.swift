import SwiftUI

/// A tiny, self-contained UI component with **pure inputs** so it can preview instantly
/// without booting your app, networking, or hitting storage.
struct JournalCard: View {
    // MARK: - Inputs (pure data only)
    let title: String
    let excerpt: String
    let date: Date
    var pinned: Bool = false

    /// Optional actions (no-op by default so previews never depend on app state)
    var onTap: (() -> Void)? = nil
    var onPinToggle: (() -> Void)? = nil

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            Text(excerpt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            footer
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(radius: 1, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.quaternary)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Subviews
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 8)
            PinButton(isPinned: pinned) { onPinToggle?() }
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
        let pinnedText = pinned ? ", pinned" : ""
        return "Journal card, \(title)\(pinnedText). Dated \(date.formatted(date: .abbreviated, time: .shortened)). \(excerpt)"
    }
}

// MARK: - Pin Button (local, lightweight)
private struct PinButton: View {
    let isPinned: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(isPinned ? "Pinned" : "Pin", systemImage: isPinned ? "pin.fill" : "pin")
                .labelStyle(.iconOnly)
                .imageScale(.medium)
                .foregroundStyle(isPinned ? .primary : .secondary)
                .padding(6)
                .background(
                    Circle()
                        .fill(isPinned ? Color.secondary.opacity(0.15) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPinned ? "Unpin entry" : "Pin entry")
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
    @State private var pinned = true

    var body: some View {
        JournalCard(
            title: JournalCard.sampleTitle,
            excerpt: JournalCard.sampleExcerpt,
            date: .now,
            pinned: pinned,
            onTap: { /* no-op for harness */ },
            onPinToggle: { pinned.toggle() }
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview("JournalCard · light") {
    JournalCardHarness()
}

#Preview("JournalCard · dark") {
    JournalCardHarness()
}

#Preview("JournalCard · long text") {
    JournalCard(
        title: "Weekly review and planning checklist for Q4",
        excerpt: "What went well: shipped UI preview harnesses, stabilized Xcode canvas. What to improve: fewer side effects in initializers, mock services end-to-end. Next: connect Supabase after UI is final.",
        date: .now.addingTimeInterval(-36_00),
        pinned: false
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
