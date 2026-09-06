import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum LoopLineTheme {
    static let appBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.08, blue: 0.07, alpha: 1)
            : UIColor(red: 0.97, green: 0.94, blue: 0.90, alpha: 1)
    })

    static let groupedBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.10, blue: 0.09, alpha: 1)
            : UIColor(red: 0.94, green: 0.91, blue: 0.86, alpha: 1)
    })

    static let surface = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.14, blue: 0.12, alpha: 1)
            : UIColor(red: 1.00, green: 0.99, blue: 0.97, alpha: 1)
    })

    static let elevatedSurface = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.19, blue: 0.16, alpha: 1)
            : UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1)
    })

    static let separator = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.33, green: 0.30, blue: 0.26, alpha: 1)
            : UIColor(red: 0.86, green: 0.82, blue: 0.76, alpha: 1)
    })

    static let subtleStroke = separator.opacity(0.72)
    static let mutedFill = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.17, blue: 0.15, alpha: 1)
            : UIColor(red: 0.92, green: 0.89, blue: 0.83, alpha: 1)
    })
    static let progressTrack = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.28, green: 0.26, blue: 0.22, alpha: 1)
            : UIColor(red: 0.90, green: 0.87, blue: 0.81, alpha: 1)
    })
    static let progressFill = accent
    static let accent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.42, green: 0.78, blue: 0.70, alpha: 1)
            : UIColor(red: 0.18, green: 0.48, blue: 0.43, alpha: 1)
    })
    static let accentSoft = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.23, blue: 0.21, alpha: 1)
            : UIColor(red: 0.87, green: 0.94, blue: 0.92, alpha: 1)
    })
    static let primaryText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.94, green: 0.92, blue: 0.88, alpha: 1)
            : UIColor(red: 0.10, green: 0.10, blue: 0.09, alpha: 1)
    })
    static let secondaryText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.66, green: 0.62, blue: 0.56, alpha: 1)
            : UIColor(red: 0.52, green: 0.49, blue: 0.44, alpha: 1)
    })
    static let destructive = Color(.systemRed)
    static let shadow = Color.black.opacity(0.06)
    static let cornerRadius: CGFloat = 14
    static let compactCornerRadius: CGFloat = 10

    static let primaryActionBackground = accent

    static let primaryActionForeground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.04, green: 0.06, blue: 0.05, alpha: 1)
            : .white
    })

    static let readingBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.08, blue: 0.07, alpha: 1)
            : UIColor(red: 0.97, green: 0.94, blue: 0.90, alpha: 1)
    })
    static let readingPanel = surface
    static let readingPrimaryText = primaryText
    static let readingSecondaryText = secondaryText
    static let readingStroke = subtleStroke
    static let readingControlFill = elevatedSurface
    static let readingStripFill = surface
    static let readingGuide = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.70, green: 0.56, blue: 0.23, alpha: 1)
            : UIColor(red: 0.98, green: 0.83, blue: 0.41, alpha: 1)
    })
    static let mediaHintBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.16, blue: 0.15, alpha: 0.92)
            : UIColor(red: 1.00, green: 0.99, blue: 0.97, alpha: 0.92)
    })

    static func badgeForeground(for sourceType: ImportSource) -> Color {
        switch sourceType {
        case .pdf:
            Color(red: 0.73, green: 0.31, blue: 0.04)
        case .image:
            accent
        case .text:
            Color(red: 0.43, green: 0.34, blue: 0.77)
        }
    }

    static func badgeBackground(for sourceType: ImportSource) -> Color {
        switch sourceType {
        case .pdf:
            Color.orange.opacity(0.13)
        case .image:
            accentSoft
        case .text:
            Color.purple.opacity(0.12)
        }
    }
}

struct LoopLinePrimaryButtonStyle: ButtonStyle {
    var isFullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(LoopLineTheme.primaryActionForeground)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(minHeight: 54)
            .padding(.horizontal, 20)
            .background(LoopLineTheme.primaryActionBackground, in: RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
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
            .frame(minHeight: 52)
            .padding(.horizontal, 16)
            .background(LoopLineTheme.surface, in: RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous)
                    .stroke(tint.opacity(0.22), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct LoopLineDangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, 16)
            .background(LoopLineTheme.destructive, in: RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

struct LoopLineIconButtonStyle: ButtonStyle {
    var size: CGFloat = 56
    var foregroundColor: Color = .primary
    var backgroundColor: Color = LoopLineTheme.surface

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .frame(width: size, height: size)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
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
                .foregroundStyle(LoopLineTheme.secondaryText)

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LoopLineTheme.accent)
            }
        }
    }
}

struct LoopLineSourceBadge: View {
    let sourceType: ImportSource

    var body: some View {
        Text(shortLabel)
            .font(.caption.weight(.semibold))
            .foregroundStyle(LoopLineTheme.badgeForeground(for: sourceType))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(LoopLineTheme.badgeBackground(for: sourceType), in: Capsule())
    }

    private var shortLabel: String {
        switch sourceType {
        case .pdf:
            "PDF"
        case .image:
            "Image"
        case .text:
            "Text"
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
                .foregroundStyle(LoopLineTheme.accent)

            Text(label ?? sourceTypeShortName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(LoopLineTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LoopLineTheme.accentSoft, in: RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LoopLineTheme.compactCornerRadius, style: .continuous)
                .stroke(LoopLineTheme.subtleStroke, lineWidth: 1)
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
                    .fill(LoopLineTheme.progressTrack)
                Capsule()
                    .fill(LoopLineTheme.progressFill)
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
                .foregroundStyle(LoopLineTheme.primaryText)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.caption)
                .foregroundStyle(LoopLineTheme.secondaryText)
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
            .foregroundStyle(LoopLineTheme.secondaryText)
    }
}
