# LoopLine - Knitting App

LoopLine is a simple SwiftUI iOS app for managing knitting projects, importing patterns, and tracking progress while knitting.

## Goal

Ship a small first version quickly, then refine it based on real use.

The first release focuses on:

- Getting a pattern into the app quickly.
- Tracking row, repeat, and stitch progress without losing place.
- Making patterns easier to read while knitting.
- Keeping the architecture simple enough to extend safely.

## Current MVP Features

- Project library.
- Create, edit, and delete projects.
- Import pattern source from PDF.
- Import pattern source from image.
- Paste pattern text.
- Text reading mode with active row highlighting.
- PDF reading mode with zoom/pan and markup support.
- Image reading mode.
- Row counter.
- Repeat counter.
- Stitch counter.
- Notes and row reminders.
- Reading mode settings for large controls and guide opacity.
- Local persistence with SwiftData.
- Local file storage for imported PDFs and images.

## Tech Stack

- Swift
- SwiftUI
- SwiftData
- PDFKit
- PencilKit
- PhotosUI
- Local file storage
- Apple-native frameworks only

## Project Structure

```text
LoopLine/
├── App/
├── Models/
├── Services/
├── ViewModels/
├── Views/
├── Assets.xcassets
└── ContentView.swift

Docs/
├── minimal-datamodel.md
└── project-overview.md
```

## Architecture

The app follows a pragmatic SwiftUI structure:

- `Models/` contains SwiftData models, domain enums, and simple data types.
- `Views/` contains SwiftUI layout and UI composition.
- `ViewModels/` contains screen-specific state, presentation logic, validation, and user flows.
- `Services/` contains reusable technical helpers for storage, import, cleanup, and file handling.

The current persisted models are:

| Model | Purpose |
|---|---|
| `Project` | Main knitting project data and tracking state. |
| `ProjectNote` | Notes and row-specific reminders. |
| `AppSettings` | Reading mode preferences. |

## Documentation

See `Docs/` for project notes:

- `Docs/project-overview.md`: Current project structure, responsibilities, features, and flows.
- `Docs/minimal-datamodel.md`: Data model notes for the MVP.

## Current Status

The app has moved beyond initial setup and now includes the MVP shell, local persistence, project management, import flows, reading modes, counters, notes, settings, and a clearer `Models` / `Views` / `ViewModels` / `Services` structure.

Known scope boundaries for the MVP:

- No sync or backend.
- No Ravelry integration.
- No OCR or AI parsing.
- No Apple Watch support.
- No social/community features.
- No complex settings system.
