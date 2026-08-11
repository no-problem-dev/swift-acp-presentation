import ACPCore

/// A UI-agnostic semantic snapshot, reduced from the ACP `session/update` stream.
///
/// It holds only meaning — the kind and status of tool calls, the execution plan, the response text —
/// and no display wording or icons. Turning that into labels and phrases for a view is the job of
/// ``SessionCopy`` and the view itself.
public struct SessionViewState: Equatable, Sendable {
    /// The session's overall activity state.
    public enum Activity: Equatable, Sendable {
        /// The initial state. No update has been received yet.
        case idle
        /// A tool call or a thought chunk has arrived and work is in progress.
        case working
        /// The completed state. `apply` and `reduce` never set it, so it only occurs when the
        /// caller sets it explicitly.
        case completed
    }

    /// The session's overall activity state, derived from the stream.
    public var activity: Activity
    /// The execution plan the agent reported. Empty when it has reported none.
    public var plan: [PlanEntry]
    /// The tool calls in the order they were announced. Updates are correlated by id.
    public var toolCalls: [ToolCallView]
    /// The agent's response text, in chunk order.
    public var messages: [String]
    /// The agent's surfaced reasoning log, in chunk order.
    public var thoughts: [String]

    /// Creates the state from each field. Every parameter has a default, so calling it with no
    /// arguments gives the initial state (`activity: .idle`, every collection empty).
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

    /// Applies a single `SessionUpdate` to the state.
    ///
    /// Total — it handles every `SessionUpdate` case exhaustively. Testing the whole stream is
    /// complete through this one method.
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

    /// Reduces a sequence of `SessionUpdate`s into a new `SessionViewState`.
    public static func reduce(_ updates: some Sequence<SessionUpdate>) -> SessionViewState {
        var state = SessionViewState()
        for update in updates { state.apply(update) }
        return state
    }
}

/// A tool call as the UI sees it.
///
/// It holds the id, title, kind and status; the view turns those into an icon and localized wording.
public struct ToolCallView: Equatable, Sendable, Identifiable {
    /// The identifier of the tool call. The key that correlates an update with an existing call.
    public let id: ToolCallId
    /// The heading for the tool call as the agent reported it. An update can change it.
    public var title: String
    /// The kind of tool. Used to pick an icon and localized wording.
    public var kind: ToolKind
    /// The execution status (in progress, completed, failed, and so on).
    public var status: ToolCallStatus

    /// Creates the tool call representation from each field.
    public init(id: ToolCallId, title: String, kind: ToolKind, status: ToolCallStatus) {
        self.id = id
        self.title = title
        self.kind = kind
        self.status = status
    }
}

private extension ContentChunk {
    /// Returns the plain text when the content is a text block.
    var text: String? {
        if case let .text(value) = content { return value.text }
        return nil
    }
}
