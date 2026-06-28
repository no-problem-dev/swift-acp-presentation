import Foundation
import ACPCore

/// セマンティックな活動情報をローカライズ済みのユーザー向け文言に変換するコピー層。
///
/// エージェントとプロトコルは「何が起きているか」という意味（例: `tool_call.kind == .search`）だけを送出し、
/// "Web を検索しています" のような表示文言はすべてこの型が担う。
/// 状態を持たない名前空間として機能する。
public enum SessionCopy {
    /// ツール呼び出しの種別に対応するローカライズ済み実行中フレーズを返す。
    public static func toolActivity(_ kind: ToolKind) -> String {
        localized(toolKey(for: kind))
    }

    /// セッション全体のアクティビティ状態に対応するローカライズ済みラベルを返す。
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
