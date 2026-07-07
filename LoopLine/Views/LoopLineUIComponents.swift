import SwiftUI

struct LoopLinePrimaryButtonStyle: ButtonStyle {
    var isFullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(minHeight: 50)
            .padding(.horizontal, 18)
            .background(Color.primary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

struct LoopLineSecondaryButtonStyle: ButtonStyle {
    var tint: Color = .primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(tint.opacity(0.28), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct LoopLineIconButtonStyle: ButtonStyle {
    var size: CGFloat = 56
    var foregroundColor: Color = .primary
    var backgroundColor: Color = Color(.secondarySystemBackground)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .frame(width: size, height: size)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

struct LoopLineSectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
    }
}

struct LoopLineSourceBadge: View {
    let sourceType: ImportSource

    var body: some View {
        Label(sourceType.displayName, systemImage: iconName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground), in: Capsule())
    }

    private var iconName: String {
        switch sourceType {
        case .pdf:
            "doc.richtext"
        case .image:
            "photo"
        case .text:
            "text.alignleft"
        }
    }
}

struct LoopLineSourcePlaceholder: View {
    let sourceType: ImportSource
    var label: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.title2.weight(.medium))
                .foregroundStyle(.secondary)

            Text(label ?? sourceTypeShortName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
        }
    }

    private var iconName: String {
        switch sourceType {
        case .pdf:
            "doc.richtext"
        case .image:
            "photo"
        case .text:
            "text.alignleft"
        }
    }

    private var sourceTypeShortName: String {
        switch sourceType {
        case .pdf:
            "PDF"
        case .image:
            "IMG"
        case .text:
            "TEXT"
        }
    }
}

struct LoopLineProgressBar: View {
    let progress: Double?

    var body: some View {
        GeometryReader { geometry in
            let clampedProgress = min(max(progress ?? 0, 0), 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                Capsule()
                    .fill(Color.secondary)
                    .frame(width: max(geometry.size.width * clampedProgress, clampedProgress > 0 ? 12 : 0))
            }
        }
        .frame(height: 8)
    }
}

struct LoopLineStatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

struct LoopLineFieldLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
    }
}
