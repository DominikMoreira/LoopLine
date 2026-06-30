# AGENTS.md

## Project overview

This repository contains a simple SwiftUI iOS app for knitting project tracking.

The first release is intentionally small and focused on:
- Fast project setup from PDF, image, or pasted pattern text
- Row and repeat tracking
- Notes and row reminders
- A polished reading mode with guides, large tap targets, and dark mode

The goal is to ship fast and refine later.

## Core principles

- Keep everything as simple as possible.
- Prefer straightforward SwiftUI solutions.
- Do not overengineer.
- Build only what is needed for the current MVP.
- Optimize for clarity and speed of implementation.

## MVP scope

Build only features that support the current V1:

- Project library
- Create/edit/delete project
- Import from PDF, image, or pasted text
- Reading mode
- Row counter
- Repeat counter
- Notes
- Row reminders
- Dark mode
- Large controls

Do not add:

- Ravelry sync
- Apple Watch support
- OCR or AI parsing
- Social/community features
- Advanced annotation tools
- Analytics dashboards
- Complex settings systems
- Premature abstractions for future features

## Architecture rules

Project structure should stay simple:

- App
- Models
- Views
- ViewModels
- Services

Rules:
- Keep views focused on UI.
- Keep business logic out of views.
- Keep models small and practical.
- Prefer local state for temporary form input.
- Persist only the minimal required app state.
- Derive display values instead of storing them when possible.

## Data model guidance (more on that in Docs/minimal-datamodel.md)

Current minimal persisted models:
- Project
- ProjectNote
- AppSettings

Temporary draft models:
- NewProjectDraft
- NoteDraft

Important:
- Do not introduce new persisted models unless clearly necessary.
- Do not split models for hypothetical future use cases.
- Keep source handling simple and practical.

## Code style

- Write clear, production-oriented Swift.
- Prefer small focused files.
- Use descriptive names.
- Avoid clever abstractions.
- Avoid unnecessary protocols.
- Avoid unnecessary generic infrastructure.
- Keep functions short and readable.
- Add comments only when they clarify non-obvious intent.

## Dependencies

- Prefer Apple-native frameworks first.
- Do not add third-party dependencies without explicit approval.
- Keep the dependency footprint as small as possible.

## SwiftUI guidance

- Build screens in small increments.
- Make one screen work before expanding behavior.
- Prefer composition over large monolithic views.
- Keep preview support where it is useful.
- Do not mix too much state management into one view.

## Persistence guidance

- Use one local persistence solution.
- Current likely choice: SwiftData.
- Keep persistence wiring simple.
- Do not add sync, cloud, or server logic in V1.

## File change rules

- Do not rename major files or folders without approval.
- Do not refactor unrelated code.
- Do not introduce large structural changes unless requested.
- Stay close to the existing project layout.

## Working style

When implementing:
1. Start with the smallest working version.
2. Make it compile.
3. Keep the change scoped.
4. Avoid solving future problems too early.

When asked to add a feature:
- Implement only the requested scope.
- If something is ambiguous, choose the simplest reasonable option.
- If a decision could affect architecture, ask first.

## Documentation

- Keep documentation concise.
- Update docs only when implementation meaningfully changes the plan.
- Prefer short practical notes over long theoretical explanations.

## Build and test expectations

Before considering work done:
- The project should compile.
- New code should match the current structure.
- No unnecessary warnings should be introduced.
- The implementation should stay inside MVP scope.

## If unsure

If there is a choice between:
- simple vs sophisticated
- practical vs abstract
- MVP vs future-proof

Choose:
- simple
- practical
- MVP
