# LoopLine Project Overview

## Purpose
LoopLine is a SwiftUI iOS app for managing knitting projects and reading knitting patterns while working. The current version is intentionally small and focused on the MVP: local project tracking, practical imports, clear reading views, large controls, and simple architecture.

## Current Features
- Project library with an empty state and project cards.
- Create, edit, and delete projects.
- Choose a pattern source when creating a project:
  - PDF file
  - Image or screenshot
  - Pasted text
- Text reading mode with active row highlighting and large counters.
- PDF reading mode with PDF display, zoom/pan, and markup support.
- Image reading mode for imported images.
- Row, repeat, and stitch counters.
- Notes and row-specific reminders.
- Settings for large controls and guide opacity.
- Local persistence with SwiftData and local file storage for imported PDFs and images.

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

## Area Responsibilities
### App
Contains the app entry point and SwiftData setup. `LoopLineApp` registers the persisted models `Project`, `ProjectNote`, and `AppSettings` in the model container.

### Models
Contains data and simple domain types:

- `Project`: Main SwiftData model for a knitting project.
- `ProjectNote`: SwiftData model for notes and reminders.
- `AppSettings`: Persisted app settings.
- `ImportSource`: Project source type: PDF, image, or text.
- `ReadingTrackingMetric`: Tracking metric selection for PDF reading mode.

Models should not contain technical file handling or view logic.

### Services
Contains reusable technical helpers:

- `ImportedPDFStorage`: Copies, resolves, and deletes imported PDFs.
- `ImportedImageStorage`: Stores, resolves, and deletes imported images.
- `PatternTextNormalizer`: Converts pasted pattern text into readable rows.
- `PDFMarkupStorage`: Saves and loads PDF markup data.
- `ProjectCleanupService`: Removes imported files when projects are deleted or drafts are discarded.

### ViewModels
Contains view-related logic, state, and workflows:

- `ProjectListViewModel`: Project creation, deletion confirmation, and delete flow.
- `CreateProjectViewModel`: Form state, PDF/image import, validation, and draft cleanup.
- `ProjectDetailViewModel`: Display text, counter actions, notes, text import, and project deletion.
- `ReadingModeViewModel`: Active row, reminder text, counters, reset flow, and notes in reading mode.
- `PDFReadingViewModel`: PDF URL resolution, selected tracking metric, markup state, and counters.
- `ImageReadingViewModel`: Stored image reference validation.
- `SettingsViewModel`: Settings initialization, saving, and app version display.

### Views
Contains SwiftUI layout and UI composition:

- `ProjectListView`: Project library and create sheet.
- `ProjectDetailView`: Project details, notes, tracking, and actions.
- `ReadingModeView`: Text-based reading mode.
- `PDFReadingView`: PDF reading mode and PDFKit/PencilKit bridge.
- `ImageReadingView`: Image-based reading mode.
- `SettingsView`: Reading mode settings and app info.
- `LoopLineUIComponents`: Shared UI components and styles.
- `StoredImagePreview`: Imported image preview.
- `PreviewModelContainer`: SwiftData container for previews.

Views should mostly contain layout, bindings, and direct UI events.

## Data Model Summary
| Model | Responsibility |
|---|---|
| `Project` | Stores project name, source, tracking state, rows, text source, file reference, and notes. |
| `ProjectNote` | Stores a note, optionally attached to a row. |
| `AppSettings` | Stores global reading mode preferences. |

## Important App Flows
- New project: `CreateProjectView` collects input, `CreateProjectViewModel` manages the draft and imports, and `ProjectListViewModel` creates the persisted `Project`.
- Delete project: The ViewModel removes imported files through services before deleting the SwiftData project.
- Text import: Pasted text is trimmed and converted into rows through `PatternTextNormalizer`.
- Reading mode: The ViewModel controls active row, counters, and reminders; the View renders content and controls.
- PDF markup: `PDFReadingView` presents PDFKit/PencilKit, while `PDFMarkupStorage` stores markup data next to the PDF.

## MVP Boundaries
The current app is deliberately small. It does not include sync, a backend, Ravelry integration, OCR, AI parsing, Apple Watch support, social features, analytics, or a complex settings system.
