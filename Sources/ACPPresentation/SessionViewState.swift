import ACPCore

/// A UI-agnostic, semantic snapshot of an agent session, reduced from the ACP
/// `session/update` stream. It carries *meaning* (a tool call's kind and
/// status, the plan, the answer text) — never presentation. Turning this into
/// labels, icons, and localized phrases is the job of the copy layer and the
/// view, so wording stays out of the domain.
public struct SessionViewState: Equatable, Sendable {
    public enum Activity: Equatable, Sendable {
        case idle
        case working
        case completed
    }

    /// Overall activity, derived from the stream.
    public var activity: Activity
    /// The agent's current execution plan, if reported.
    public var plan: [PlanEntry]
    /// Tool calls in announcement order, keyed by id so updates correlate.
    public var toolCalls: [ToolCallView]
    /// The agent's answer text (message chunks, in order).
    public var messages: [String]
    /// The agent's surfaced reasoning, in order.
    public var thoughts: [String]

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

    /// Reduce one update into the state. Pure and total — every `SessionUpdate`
    /// case is handled, so the whole stream is covered by tests of this method.
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

    /// Build a state by reducing a whole sequence of updates.
    public static func reduce(_ updates: some Sequence<SessionUpdate>) -> SessionViewState {
        var state = SessionViewState()
        for update in updates { state.apply(update) }
        return state
    }
}

/// A tool call as the UI sees it: identity plus the semantic kind/status that a
/// view turns into an icon and a localized status phrase.
public struct ToolCallView: Equatable, Sendable, Identifiable {
    public let id: ToolCallId
    public var title: String
    public var kind: ToolKind
    public var status: ToolCallStatus

    public init(id: ToolCallId, title: String, kind: ToolKind, status: ToolCallStatus) {
        self.id = id
        self.title = title
        self.kind = kind
        self.status = status
    }
}

private extension ContentChunk {
    /// The plain text of a chunk whose content is a text block, if any.
    var text: String? {
        if case let .text(value) = content { return value.text }
        return nil
    }
}
