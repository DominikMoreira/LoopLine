# LoopLine - Knitting App

A simple SwiftUI iOS app for following knitting patterns and tracking progress while knitting.

## Goal

Ship a small first version fast, then refine later.

The first release focuses on:
- Getting a pattern into the app quickly
- Tracking progress without losing place
- Making the pattern easy to read while knitting

## MVP scope

- Create projects
- Import pattern from PDF
- Import pattern from image
- Paste pattern text
- Row counter
- Repeat counter
- Stitch counter
- Notes and row reminders
- Reading mode
- Horizontal and vertical guides
- Dark mode
- Large tap targets

## Tech stack

- Swift
- SwiftUI
- Local persistence only
- Minimal dependencies

## Project structure

```text
.
├── App/
├── Models/
├── Views/
├── ViewModels/
├── Services/
├── Docs/
├── README.md
└── AGENTS.md
```

## Docs

See `Docs/` for planning and implementation notes:
- Pre-implementation checklist
- Minimal data model
- Revised minimal data model

## Current status

Project setup and planning phase.

Next steps:
- Add docs and agent instructions
- Configure Codex workflow
- Build the first app shell
- Implement the minimal data layer
- Build the project list screen
