# Pre-Implementation Checklist

This document captures the current decisions for the first release of the knitting companion iOS app. The goal is to keep the project as simple as possible, ship fast, and refine later.

## 1. Freeze MVP

### Objectives for Release 1.0

- Get a pattern into the app quickly.
- Track progress without losing place.
- Make the pattern easy to read while knitting.

### Must-Have Features

| Area | Feature | Why it belongs in V1 |
|---|---|---|
| Setup | Create project from PDF | PDF import is a core expectation in leading apps. |
| Setup | Create project from image | Competitors support image/photo-based patterns, so this keeps setup flexible. |
| Setup | Paste pattern text | This gives a lightweight path for blog patterns or copied instructions without building web import yet. |
| Setup | Project name + optional photo | Basic organization matters, but it should stay simple in V1. Project-centric workflows are common in successful apps. |
| Tracking | Main row counter | This is the category’s most basic value. |
| Tracking | Repeat counter | Repeat handling is explicitly important in knitCompanion and Row Counter-style apps. |
| Tracking | Row notes/reminders | Row-specific reminders are a proven “don’t miss a step” feature. |
| Reading | Reading mode for PDF/image/text | Pattern-following is the heart of the experience. |
| Reading | Horizontal guide | Helps users keep track of the current line or row. |
| Reading | Vertical guide | Especially useful for charts and dense instructions. |
| Reading | Zoom + pan | Necessary for charts, symbols, and small pattern text. User praise for enlarge/readability is a recurring theme in top apps. |
| Reading | Dark mode | Long-session readability and modern iOS expectations make this a practical baseline. |
| UX | Large tap targets | Reliable interaction matters because knitters often use the app one-handed or mid-project. Strong row-counter apps emphasize ease of use. |

### V1 Feature Definition

- Project library with create, edit, and delete project actions; cover photo is optional.
- Import pattern from PDF, image, or pasted text.
- Project detail screen with pattern, current row, current repeat, and notes summary.
- Row counter with increment, decrement, reset confirmation, and repeat counter.
- Row-specific reminders, for example: “On row 12, start decreases.”
- Reading mode with zoom, pan, horizontal guide, vertical guide, and dark mode.
- Simple notes, either project-wide notes or row-linked notes.
- Large controls and a calm, distraction-free knitting screen inspired by successful competitors.

## 2. Tech Stack

- SwiftUI + Swift.
- One local persistence solution.
- Current candidate: SwiftData.
- Use as few dependencies as possible.
- Prefer native Apple frameworks first.


## 3. Architecture

### Structure

- App
- Models
- Views
- ViewModels
- Services

### Rules

- Keep views focused on UI.
- Keep business logic out of views.
- Do not build for hypothetical future features.
- Keep the architecture simple and practical.
- Add abstraction only when it solves a real problem.

## 5. Styleguide & Essential Screens

- Look at Figma Designs
