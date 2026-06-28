---
title: swift-acp-presentation README
created: 2026-06-27
tags: [swift, acp, presentation, spm]
status: active
---

English | [日本語](./README.ja.md)

# swift-acp-presentation

> A presentation-layer package that converts ACP `session/update` streams into the UI-agnostic `SessionViewState` and encapsulates all user-facing copy on the host side.

## Overview

`swift-acp-presentation` is responsible for converting the agent activity stream (`SessionUpdate`) provided by [swift-acp](https://github.com/no-problem-dev/swift-acp) into the state required for screen rendering.

The domain (agent/protocol) emits only semantics (`tool_call.kind == .search`), while display phrases like "Searching the web" live exclusively in this package's String Catalog. This means copy changes and localization can be completed without modifying the domain layer.

### Modules

| Module | Description |
|---|---|
| `ACPPresentation` | Provides the `SessionViewState` reducer and the `SessionCopy` copy layer |

### Key Types

| Type | Kind | Description |
|---|---|---|
| `SessionViewState` | struct | A UI snapshot reduced from the ACP `session/update` stream |
| `SessionViewState.Activity` | enum | Overall session activity state (`.idle` / `.working` / `.completed`) |
| `ToolCallView` | struct | A UI-facing view of a tool call holding its ID, title, kind, and status |
| `SessionCopy` | enum | A copy layer that returns localized phrases (a stateless namespace) |

## Supported Platforms

| Platform | Minimum Version |
|---|---|
| iOS | 16.0 |
| macOS | 13.0 |
| tvOS | 16.0 |
| watchOS | 9.0 |
| visionOS | 1.0 |

## Installation

Add the dependency to your `Package.swift`.

```swift
dependencies: [
    .package(
        url: "https://github.com/no-problem-dev/swift-acp-presentation.git",
        from: "0.1.0"
    ),
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "ACPPresentation", package: "swift-acp-presentation"),
        ]
    ),
]
```

## Usage

### SessionViewState — Reducing the Stream

Apply one update at a time with `apply(_:)`, or convert in bulk with `reduce(_:)`.

```swift
import ACPCore
import ACPPresentation

// Reduce the entire stream at once
let updates: [SessionUpdate] = fetchSessionUpdates()
let state = SessionViewState.reduce(updates)

// Apply incrementally as the stream arrives
var state = SessionViewState()
for update in liveStream {
    state.apply(update)
    render(state)
}
```

### SessionViewState Properties

```swift
// Overall session activity
switch state.activity {
case .idle:      // Agent is waiting
case .working:   // Tool call or thinking in progress
case .completed: // Set externally; not emitted by apply/reduce
}

// Execution plan (if the agent reported one)
for entry in state.plan {
    print(entry.content)   // "search the web"
    print(entry.priority)  // .high / .medium / .low
    print(entry.status)    // .pending / .inProgress / .completed / ...
}

// Tool calls in announcement order (id correlates updates)
for call in state.toolCalls {
    print(call.id)     // ToolCallId
    print(call.title)  // "search"
    print(call.kind)   // .search / .read / .edit / ...
    print(call.status) // .inProgress / .completed / .failed
}

// Agent answer text (chunk order)
let fullAnswer = state.messages.joined()

// Agent reasoning log (chunk order)
let reasoningLog = state.thoughts.joined(separator: "\n")
```

### SessionCopy — Retrieving Localized Phrases

```swift
import ACPPresentation

// ToolKind → "doing X" phrase (Japanese default: "Web を検索しています")
let phrase = SessionCopy.toolActivity(.search)

// Session activity → label (Japanese default: "作業しています")
let label = SessionCopy.activity(.working)
```

#### Supported Tool Kinds and Phrases (Japanese / English)

| `ToolKind` | Japanese | English |
|---|---|---|
| `.read` | ファイルを読んでいます | Reading a file |
| `.edit` | 編集しています | Editing |
| `.search` | Web を検索しています | Searching the web |
| `.execute` | コマンドを実行しています | Running a command |
| `.fetch` | ページを読み込んでいます | Fetching a page |
| `.think` | 考えています | Thinking |
| (unknown) | ツールを使っています | Using a tool |

Unknown `ToolKind` values fall back to the default phrase (`tool.default`).

### SwiftUI Integration Example

```swift
import SwiftUI
import ACPPresentation

struct SessionStatusView: View {
    let state: SessionViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(SessionCopy.activity(state.activity))
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(state.toolCalls) { call in
                Label(
                    SessionCopy.toolActivity(call.kind),
                    systemImage: iconName(for: call.kind)
                )
                .opacity(call.status == .completed ? 0.5 : 1.0)
            }

            if !state.messages.isEmpty {
                Text(state.messages.joined())
            }
        }
    }

    private func iconName(for kind: ToolKind) -> String {
        switch kind {
        case .search:  return "magnifyingglass"
        case .read:    return "doc.text"
        case .edit:    return "pencil"
        case .execute: return "terminal"
        case .fetch:   return "globe"
        default:       return "wrench.and.screwdriver"
        }
    }
}
```

## Architecture

```
swift-acp (ACPCore)
    └── SessionUpdate, ToolCall, ToolKind, Plan, ...
            │
            ▼
swift-acp-presentation (ACPPresentation)          ← this package
    ├── SessionViewState  — semantic reduction
    └── SessionCopy       — localized phrases
            │
            ▼
Host App / SwiftUI View
    — Build views from SessionViewState properties
    — Retrieve phrases via SessionCopy
```

- `swift-acp` holds only protocol and domain types. It carries no copy.
- `swift-acp-presentation` owns the presentation responsibility. Its only domain dependency is `ACPCore`.
- The host app obtains state and copy through this package and constructs SwiftUI views.

## License

MIT License — see [LICENSE](./LICENSE) for details.

---

Last updated: 2026-06-27
