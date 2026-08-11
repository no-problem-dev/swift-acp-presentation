import Foundation
import ACPCore

/// The copy layer that turns semantic activity information into localized user-facing wording.
///
/// The agent and the protocol emit only the meaning of what is happening (for example,
/// `tool_call.kind == .search`); every display phrase, such as "Searching the web", is this type's
/// responsibility. It acts as a namespace and holds no state.
public enum SessionCopy {
    /// Returns the localized in-progress phrase for a kind of tool call.
    public static func toolActivity(_ kind: ToolKind) -> String {
        localized(toolKey(for: kind))
    }

    /// Returns the localized label for the session's overall activity state.
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

    /// `String(localized:)` and `String.LocalizationValue` are Apple-platform only, so lookup goes
    /// through `NSLocalizedString`, which reads the `.lproj` files on every platform.
    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, bundle: .module, comment: "")
    }
}
