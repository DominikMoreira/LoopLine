# AGENTS.md

## Project
LoopLine is a native SwiftUI iOS/iPadOS knitting companion app Prioritize a small, stable App Store release. Choose simple, practical solutions over speculative or overly abstract architecture.

## Architecture
- Use SwiftUI for the UI.
- Use SwiftData for local persistence.
- Follow a lightweight MVVM architecture.
- Keep views focused on presentation and user interaction.
- Move non-UI logic into small, readable models, view models, or services when appropriate.
- Prefer the latest stable Apple technologies and APIs that are suitable for the project.
- Prefer Apple frameworks. Do not add third-party dependencies without explicit approval.

## Scope Boundaries
Work only on the requested task.
Do not:
- Add unrequested features.
- Refactor unrelated code.
- Change the app architecture without approval.
- Change SwiftData models or migrations unless required for the requested task.
- Remove or alter existing functionality during UI-only work.

If a requested change conflicts with existing behavior, explain the conflict before making a destructive change.

## UI and Accessibility
- Use the Figma reference files in `Docs/Figma/iPhone/` and `Docs/Figma/iPad/` when relevant.
- Treat Figma files as visual guidance unless a task explicitly requests behavior changes.
- Reuse shared UI components where appropriate..
- Preserve iPhone and iPad usability.

## Localization
- Use `Localizable.xcstrings` for user-visible text.
- Keep English as the development language.
- Provide German translations
- Use locale-aware formatting for dates, numbers, and pluralized strings.
- Do not hard-code new user-visible English strings outside the localization system.

## Code Style
- Write idiomatic, modern Swift.
- Prefer small, readable types and functions.
- Use clear, descriptive names.
- Avoid force unwraps and force casts.
- Keep changes minimal and localized.
- Do not leave debug logging, dead code, placeholder logic, or commented-out code in finished work.
- Add comments only when they clarify non-obvious intent.

## Build and Tests
For every functional change:
1. Build the app.
2. Run the full available test suite before considering the task complete.
3. Do not finish if existing tests fail.
4. Add or update focused tests when behavior or persistence changes and the test remains simple and maintainable.
5. Clearly report any build or test that could not run, including the reason.

Do not introduce elaborate test infrastructure, mock frameworks, repositories, or dependency-injection systems solely for a small test.

## Git Workflow
- Never work directly on `main` or `master`.
- The developer creates and checks out the feature branch before Codex starts work.
- Keep each task limited to one reviewable purpose.
- Codex may create a local commit only when explicitly asked.
- Do not push, merge pull requests, change branch protection, or modify CI configuration unless explicitly asked.
- Do not modify secrets, signing credentials, provisioning profiles, or App Store Connect settings.

When creating a commit:
- Include only files related to the requested task.
- Use a concise, imperative commit message.
- Do not commit generated build output, DerivedData, credentials, or personal Xcode user data.

## Documentation
Update documentation only when the requested work changes:
- MVP scope
- User-visible behavior
- Architecture or data model
- Setup, test, or release steps

Keep documentation concise and consistent with the actual implementation.

## Completion Report
At the end of each task, report:
- What changed
- Files changed
- Any remaining limitation, decision, or follow-up

Do not claim that a build, test, UI check, or device check passed unless it was actually performed.
