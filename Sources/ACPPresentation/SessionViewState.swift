import ACPCore

/// ACP の `session/update` ストリームをリデュースした UI 非依存のセマンティックスナップショット。
///
/// ツール呼び出しの種別・ステータス、実行プラン、応答テキストなど「意味」だけを保持し、
/// 表示文言やアイコンは持たない。View 向けラベルやフレーズへの変換は ``SessionCopy`` と View が担う。
public struct SessionViewState: Equatable, Sendable {
    /// セッション全体の活動状態。
    public enum Activity: Equatable, Sendable {
        /// 初期状態。まだ更新を受け取っていない。
        case idle
        /// ツール呼び出しまたは推論チャンクを受け取り、処理中。
        case working
        /// 完了状態。`apply`/`reduce` は設定しないため、利用側が明示的に設定したときのみ取る値。
        case completed
    }

    /// ストリームから導出したセッション全体の活動状態。
    public var activity: Activity
    /// エージェントが報告した実行計画。未報告の場合は空。
    public var plan: [PlanEntry]
    /// 告知順のツールコール一覧。id でアップデートを相関付ける。
    public var toolCalls: [ToolCallView]
    /// エージェントの回答テキスト（チャンク順）。
    public var messages: [String]
    /// エージェントの表面化された推論ログ（チャンク順）。
    public var thoughts: [String]

    /// 各フィールドを指定して状態を生成する。すべて既定値を持ち、引数なしで初期状態（`activity: .idle`・各コレクション空）になる。
    public init(
        activity: Activity = .idle,
        plan: [PlanEntry] = [],
        toolCalls: [ToolCallView] = [],
        messages: [String] = [],
        thoughts: [String] = []
    ) {
        self.activity = activity
        self.plan = plan
        self.toolCalls = toolCalls
        self.messages = messages
        self.thoughts = thoughts
    }

    /// 1 件の `SessionUpdate` を状態に適用する。
    ///
    /// 全域的 — すべての `SessionUpdate` ケースを網羅的に処理する。ストリーム全体のテストはこのメソッドを通じて完結する。
    public mutating func apply(_ update: SessionUpdate) {
        switch update {
        case let .toolCall(call):
            activity = .working
            toolCalls.append(ToolCallView(
                id: call.toolCallId,
                title: call.title,
                kind: call.kind,
                status: call.status
            ))

        case let .toolCallUpdate(update):
            guard let index = toolCalls.firstIndex(where: { $0.id == update.toolCallId }) else { return }
            if let status = update.status { toolCalls[index].status = status }
            if let title = update.title { toolCalls[index].title = title }
            if let kind = update.kind { toolCalls[index].kind = kind }

        case let .plan(plan):
            self.plan = plan.entries

        case let .agentMessageChunk(chunk):
            if let text = chunk.text { messages.append(text) }

        case let .agentThoughtChunk(chunk):
            if let text = chunk.text { thoughts.append(text) }
            activity = .working

        case .userMessageChunk,
             .availableCommandsUpdate,
             .currentModeUpdate,
             .configOptionUpdate,
             .sessionInfoUpdate,
             .usageUpdate,
             .unknown:
            break
        }
    }

    /// 一連の `SessionUpdate` シーケンスをリデュースして新しい `SessionViewState` を生成する。
    public static func reduce(_ updates: some Sequence<SessionUpdate>) -> SessionViewState {
        var state = SessionViewState()
        for update in updates { state.apply(update) }
        return state
    }
}

/// UI 向けのツールコール表現。
///
/// ID・タイトル・種別・ステータスを保持し、View がアイコンとローカライズ済み文言に変換する。
public struct ToolCallView: Equatable, Sendable, Identifiable {
    /// ツール呼び出しの識別子。アップデートを既存の呼び出しに相関付けるキー。
    public let id: ToolCallId
    /// エージェントが報告したツール呼び出しの見出し。アップデートで更新されうる。
    public var title: String
    /// ツールの種別。アイコンやローカライズ済み文言への変換に使う。
    public var kind: ToolKind
    /// 実行状態（進行中・完了・失敗など）。
    public var status: ToolCallStatus

    /// 各フィールドを指定してツールコール表現を生成する。
    public init(id: ToolCallId, title: String, kind: ToolKind, status: ToolCallStatus) {
        self.id = id
        self.title = title
        self.kind = kind
        self.status = status
    }
}

private extension ContentChunk {
    /// コンテンツがテキストブロックの場合にプレーンテキストを返す。
    var text: String? {
        if case let .text(value) = content { return value.text }
        return nil
    }
}
