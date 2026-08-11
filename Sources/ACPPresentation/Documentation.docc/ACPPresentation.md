# ``ACPPresentation``

The presentation layer that converts the ACP `session/update` stream into a UI-agnostic view state and owns all user-facing copy in one place.

> **Unofficial.** Not affiliated with or endorsed by the authors of the Agent Client Protocol, and built on an unofficial Swift implementation of it. Conforming to the specification is not a goal of this project.

## Overview

`ACPPresentation` takes the semantic agent activity the ACP protocol streams (the kind and status of tool calls, the execution plan, the response text) and folds it into a ``SessionViewState`` that a view — SwiftUI or otherwise — can bind to directly.

**Separating semantics from presentation** is the heart of the design. The agent and the protocol emit only the meaning of what is happening; how it is displayed and how it is worded is entirely this library's job. Wording such as "Searching the web" exists nowhere else.

### Folding the state

``SessionViewState`` is produced either by folding the whole stream at once with ``SessionViewState/reduce(_:)``, or by accumulating events one at a time with ``SessionViewState/apply(_:)``.

```swift
import ACPPresentation
import ACPCore

// Fold the whole stream at once
let state = SessionViewState.reduce(updates)

// Or apply incrementally as updates arrive
var state = SessionViewState()
for await update in session.updates {
    state.apply(update)
}
```

### Localizing the copy

``SessionCopy`` localizes tool kinds and the session's overall activity through the String Catalog (Japanese is the default) and returns them as strings. A view only has to call ``SessionCopy/toolActivity(_:)`` or ``SessionCopy/activity(_:)`` to get the label for a given tool kind or state.

```swift
import ACPPresentation

// The heading for a tool call row
let label = SessionCopy.toolActivity(toolCallView.kind)  // e.g. "Reading a file"

// The session-wide status display
let status = SessionCopy.activity(state.activity)        // e.g. "Working"
```

## Topics

### State model

- ``SessionViewState``
- ``ToolCallView``

### Activity

- ``SessionViewState/Activity``

### Localized text

- ``SessionCopy``
