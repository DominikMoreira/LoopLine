# LoopLine — Revised Minimal Data Model Documentation

## Purpose

This document defines the revised minimal data model for the first prototype of the Loopline knitting app. The goal is still to support the current Figma screens with the smallest possible set of persisted models, while adding a few practical improvements for real file-based imports.

The model remains intentionally conservative. It stores only user-editable or behavior-driving data and derives everything else in the UI at runtime.

## Design Goal

The prototype should:

- Support all current screens.
- Avoid premature abstraction.
- Keep state management straightforward in SwiftUI.
- Separate persisted app data from temporary form state.
- Support PDF, image, and pasted-text projects in a realistic way.
- Allow small future extensions without rewriting the foundations.

## Core Principle

A simple rule guides the model design:

- Store values the user edits or that the app must remember.
- Derive values that are only displayed.

Examples:

- Store: current row, repeat counter, notes, settings, import source reference.
- Derive: progress percentage, total rows, active reminder text, note preview.

## Minimal Persisted Models

The prototype still needs only three persisted models:

1. `Project`
2. `ProjectNote`
3. `AppSettings`

These three models are enough to support the project list, empty state, project detail, reading mode, add note flow, and settings screen.

## What Changed From The First Version

This revision keeps the overall structure the same, but improves three practical areas:

1. Cover images are modeled as a stored path/reference rather than an asset-style name.
2. Imported pattern sources can now be retained with a minimal file reference or text payload.
3. Progress and row handling are documented more defensively for implementation.

## Model Overview

| Model | Role | Why it exists |
|---|---|---|
| `Project` | Main entity of the app | Holds everything needed for one knitting project |
| `ProjectNote` | Reminder or note attached to a project | Supports row-linked reminders and general notes |
| `AppSettings` | Global app preferences | Stores reading-related settings used across the app |

## Canonical Swift Model

```swift
enum ImportSource: String, Codable, CaseIterable {
    case pdf
    case image
    case text
}

struct Project: Identifiable, Codable {
    let id: UUID
    var name: String

    var coverImagePath: String?
    var subtitle: String?
    var detailMeta: String?

    var sourceType: ImportSource
    var sourceFilePath: String?
    var sourceText: String?
    var rows: [String]

    var currentRow: Int
    var repeatCurrent: Int
    var repeatTotal: Int?

    var notes: [ProjectNote]

    var totalRows: Int { rows.count }

    var clampedCurrentRow: Int {
        guard totalRows > 0 else { return 0 }
        return min(max(currentRow, 1), totalRows)
    }

    var progress: Double {
        guard totalRows > 0 else { return 0 }
        return Double(clampedCurrentRow) / Double(totalRows)
    }

    var activeNotes: [ProjectNote] {
        notes.filter { $0.rowNumber == clampedCurrentRow }
    }
}

struct ProjectNote: Identifiable, Codable {
    let id: UUID
    var text: String
    var rowNumber: Int?
}

struct AppSettings: Codable {
    var readingDarkMode: Bool
    var largeControls: Bool
    var guideOpacity: Double
}
```

## Why Each Field Exists

### Project

| Field | Type | Needed for | Notes |
|---|---|---|---|
| `id` | `UUID` | Lists, navigation, editing | Stable identity for SwiftUI and persistence |
| `name` | `String` | Project list, detail, navigation titles | Primary project label |
| `coverImagePath` | `String?` | Project list, detail, create flow | Better fit for user-selected images than an asset-style name |
| `subtitle` | `String?` | Project list | Small descriptive line such as yarn or gift note |
| `detailMeta` | `String?` | Project detail | Simple display string such as import source, date, or size |
| `sourceType` | `ImportSource` | New project flow, metadata | Keeps the import choice typed |
| `sourceFilePath` | `String?` | PDF and image projects | Stores a local reference to the imported file |
| `sourceText` | `String?` | Pasted text projects | Stores original pasted pattern text when text is the source |
| `rows` | `[String]` | Reading mode | Minimal normalized representation of pattern content |
| `currentRow` | `Int` | Detail, reading mode, list progress | Main reading position |
| `repeatCurrent` | `Int` | Detail, reading mode | Current repeat count |
| `repeatTotal` | `Int?` | Detail, reading mode | Optional repeat target, since not every project may use it |
| `notes` | `[ProjectNote]` | Detail, reading mode, notes sheet | Stores reminders and project notes |

### ProjectNote

| Field | Type | Needed for | Notes |
|---|---|---|---|
| `id` | `UUID` | Lists and editing | Stable identity |
| `text` | `String` | Note display and preview | Main note content |
| `rowNumber` | `Int?` | Row reminders | `nil` means general note, value means row-linked reminder |

### AppSettings

| Field | Type | Needed for | Notes |
|---|---|---|---|
| `readingDarkMode` | `Bool` | Reading mode appearance | Scoped to the reading experience |
| `largeControls` | `Bool` | Reading mode controls | Supports one-handed use |
| `guideOpacity` | `Double` | Reading mode guides | Best stored as a value from `0.0 ... 1.0` |

## Source Representation Strategy

The app supports three import types in V1:

- PDF
- Image
- Pasted text

To keep the model simple while still making the app usable after relaunch:

- PDF and image projects should keep a local file reference in `sourceFilePath`.
- Text projects should keep the original content in `sourceText`.
- `rows` acts as the reading-friendly representation used by the UI.

This means `rows` is not necessarily the original source. It is the minimal normalized form the reading screen can rely on.

Examples:

- For a pasted text pattern, `sourceText` and `rows` may both be populated.
- For a PDF project, `sourceFilePath` is the original source and `rows` may contain extracted or manually prepared lines.
- For an image project, `sourceFilePath` is the original source and `rows` may be empty or lightly normalized depending on the reading mode design.

## Screen-by-Screen Data Needs

### 1. Project List

The project list screen needs only a collection of `Project` values.

Each card can be rendered from:

- `name`
- `coverImagePath`
- `subtitle`
- `currentRow`
- `rows.count`
- `progress`

No separate list item model is necessary. A project card is simply a visual representation of `Project`.

### 1b. Empty State

The empty state does not need its own model.

It is a pure derived state:

```swift
projects.isEmpty
```

If there are no projects, the empty state is shown. If at least one project exists, the list is shown.

### 2. New Project

The new project flow should not write directly into `Project` while the user is still editing. A temporary draft model is cleaner.

```swift
struct NewProjectDraft {
    var name: String = ""
    var coverImageData: Data? = nil
    var sourceType: ImportSource? = nil

    var importedFileURL: URL? = nil
    var sourceText: String = ""
    var rows: [String] = []
}
```

This draft should exist only during the create flow. After confirmation, it becomes a `Project`.

### 3. Project Detail

The detail screen needs one `Project`.

It reads:

- `coverImagePath`
- `name`
- `detailMeta`
- `currentRow`
- `repeatCurrent`
- `repeatTotal`
- `progress`
- `notes`

The stat tiles still do not need extra storage:

- Current row = `currentRow`
- Repeat = `repeatCurrent` and `repeatTotal`
- Progress = derived from `currentRow` and `rows.count`

### 4. Reading Mode

Reading mode needs one `Project` and the global `AppSettings`.

Required project data:

- `sourceType`
- `sourceFilePath`
- `sourceText`
- `rows`
- `currentRow`
- `repeatCurrent`
- `repeatTotal`
- `notes`

Required settings data:

- `readingDarkMode`
- `largeControls`
- `guideOpacity`

The active reminder strip at the bottom can be derived from:

```swift
project.activeNotes
```

This means there is no need for a separate “active reminder” model.

### 5. Add Note

The add note sheet should use a temporary draft model rather than editing persisted note data from the first keystroke.

```swift
struct NoteDraft {
    var text: String = ""
    var attachToSpecificRow: Bool = false
    var rowNumber: Int = 1
}
```

When the user saves:

- If `attachToSpecificRow == true`, save the note with `rowNumber`.
- If `attachToSpecificRow == false`, save the note with `rowNumber = nil`.

The preview in the sheet is derived from the draft values and does not need its own model.

### 6. Settings

The settings screen is fully backed by `AppSettings`.

No section model or option item model is needed for V1 unless the settings list becomes much larger.

## Derived Values

These values should not be persisted because they can always be computed from the stored data.

| Derived value | Source |
|---|---|
| `totalRows` | `rows.count` |
| `progress` | `clampedCurrentRow / totalRows` |
| Empty state visibility | `projects.isEmpty` |
| Active reminders for current row | `notes.filter { $0.rowNumber == clampedCurrentRow }` |
| Note preview text | `NoteDraft` values |
| Current row label such as `Row 42/120` | `clampedCurrentRow` + `totalRows` |

This keeps the model smaller and avoids synchronization bugs.

## What Is Intentionally Not Modeled Yet

The following should stay out of the first prototype:

- Separate progress model
- Separate project list card model
- Separate reading session model
- Persistent zoom and pan state
- Complex parsed pattern structure
- Rich note categories or note colors
- Per-row annotations beyond notes
- Import pipeline state objects
- Dedicated metadata objects for yarn, needle size, tags, and deadlines

These may become useful later, but they are not required to support the current screens.

## Recommended Future Upgrade Path

If the app later needs structured pattern rows, replace:

```swift
var rows: [String]
```

with:

```swift
struct PatternRow: Identifiable, Codable {
    let id: UUID
    var number: Int
    var text: String
}
```

This upgrade should only happen when row-level metadata is truly needed, for example highlights, parsed symbols, or row-specific flags.

## SwiftUI Architecture Notes

For a straightforward prototype, the app can be organized around one top-level store that owns:

- `projects: [Project]`
- `settings: AppSettings`

That store can be exposed to the UI via `ObservableObject` or the newer observation tools. Temporary screen state such as `NewProjectDraft` and `NoteDraft` should stay local to the relevant view or sheet.

This separation gives a clear boundary:

- Persisted app state lives in the store.
- Temporary form state lives in the screen.

## Final Recommendation

For V1, the best revised minimal structure is:

- 3 persisted models: `Project`, `ProjectNote`, `AppSettings`
- 2 temporary draft models: `NewProjectDraft`, `NoteDraft`
- Minimal source retention via `sourceFilePath` or `sourceText`
- Derived values for progress, totals, empty state, preview, and active reminders

This structure is still small enough to implement quickly in SwiftUI, but more realistic for actual PDF, image, and text imports.
