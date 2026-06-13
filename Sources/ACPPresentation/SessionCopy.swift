import Foundation
import ACPCore

/// Turns the semantic facts in a `SessionViewState` into localized, user-facing
/// wording. This is the *only* place agent-activity copy lives — the agent and
/// the protocol never spell out a phrase like "Searching the web"; they report
/// `tool_call.kind == .search` and this layer localizes it.
public enum SessionCopy {
    /// A localized "doing X" phrase for a tool call's kind.
    public static func toolActivity(_ kind: ToolKind) -> String {
        localized(toolKey(for: kind))
    }

    /// A localized phrase for the session's overall activity.
    public static func activity(_ activity: SessionViewState.Activity) -> String {
        switch activity {
        case .idle: localized("activity.idle")
        case .working: localized("activity.working")
        case .completed: localized("activity.completed")
        }
    }

    private static func toolKey(for kind: ToolKind) -> String {
        switch kind.rawValue {
        case "read": "tool.read"
        case "edit": "tool.edit"
        case "search": "tool.search"
        case "execute": "tool.execute"
        case "fetch": "tool.fetch"
        case "think": "tool.think"
        default: "tool.default"
        }
    }

    private static func localized(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module)
    }
}
