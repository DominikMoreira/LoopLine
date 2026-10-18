import Foundation

enum ReadingTrackingMetric: String, CaseIterable, Identifiable {
    case row
    case stitches
    case repeatCount

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .row:
            "Row"
        case .stitches:
            "Stitches"
        case .repeatCount:
            "Repeat"
        }
    }
}

enum CounterChangeDirection: String {
    case increased
    case decreased
    case set
}

struct LastCounterChange: Equatable {
    let metric: ReadingTrackingMetric
    let value: Int
    let direction: CounterChangeDirection
    let timestamp: Date
}

extension Project {
    var lastCounterChange: LastCounterChange? {
        guard let metricRawValue = lastCounterMetricRawValue,
              let metric = ReadingTrackingMetric(rawValue: metricRawValue),
              let value = lastCounterValue,
              let directionRawValue = lastCounterChangeDirectionRawValue,
              let direction = CounterChangeDirection(rawValue: directionRawValue),
              let timestamp = lastCounterChangedAt else {
            return nil
        }

        return LastCounterChange(
            metric: metric,
            value: value,
            direction: direction,
            timestamp: timestamp
        )
    }

    func recordLastCounterChange(
        metric: ReadingTrackingMetric,
        value: Int,
        direction: CounterChangeDirection,
        timestamp: Date = .now
    ) {
        lastCounterMetricRawValue = metric.rawValue
        lastCounterValue = value
        lastCounterChangeDirectionRawValue = direction.rawValue
        lastCounterChangedAt = timestamp
    }

    func clearLastCounterChange() {
        lastCounterMetricRawValue = nil
        lastCounterValue = nil
        lastCounterChangeDirectionRawValue = nil
        lastCounterChangedAt = nil
    }
}

enum LastCounterChangeFormatter {
    static func timestampText(
        for date: Date,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return date.formatted(.dateTime.hour().minute().locale(locale))
        }

        return date.formatted(.dateTime.year().month(.abbreviated).day().hour().minute().locale(locale))
    }

    static func statusText(
        for change: LastCounterChange,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let value = change.value.formatted(.number.locale(locale))
        let timestamp = timestampText(for: change.timestamp, now: now, calendar: calendar, locale: locale)

        switch (change.metric, change.direction) {
        case (.row, .increased):
            return String(localized: "Last: Row increased to \(value) · \(timestamp)", comment: "Reading mode status line for the last row counter increase. The first placeholder is the new value and the second is the local time or date and time.")
        case (.row, .decreased):
            return String(localized: "Last: Row decreased to \(value) · \(timestamp)", comment: "Reading mode status line for the last row counter decrease. The first placeholder is the new value and the second is the local time or date and time.")
        case (.row, .set):
            return String(localized: "Last: Row set to \(value) · \(timestamp)", comment: "Reading mode status line for a directly set row counter. The first placeholder is the new value and the second is the local time or date and time.")
        case (.stitches, .increased):
            return String(localized: "Last: Stitches increased to \(value) · \(timestamp)", comment: "Reading mode status line for the last stitch counter increase. The first placeholder is the new value and the second is the local time or date and time.")
        case (.stitches, .decreased):
            return String(localized: "Last: Stitches decreased to \(value) · \(timestamp)", comment: "Reading mode status line for the last stitch counter decrease. The first placeholder is the new value and the second is the local time or date and time.")
        case (.stitches, .set):
            return String(localized: "Last: Stitches set to \(value) · \(timestamp)", comment: "Reading mode status line for a directly set stitch counter. The first placeholder is the new value and the second is the local time or date and time.")
        case (.repeatCount, .increased):
            return String(localized: "Last: Repeat increased to \(value) · \(timestamp)", comment: "Reading mode status line for the last repeat counter increase. The first placeholder is the new value and the second is the local time or date and time.")
        case (.repeatCount, .decreased):
            return String(localized: "Last: Repeat decreased to \(value) · \(timestamp)", comment: "Reading mode status line for the last repeat counter decrease. The first placeholder is the new value and the second is the local time or date and time.")
        case (.repeatCount, .set):
            return String(localized: "Last: Repeat set to \(value) · \(timestamp)", comment: "Reading mode status line for a directly set repeat counter. The first placeholder is the new value and the second is the local time or date and time.")
        }
    }
}
