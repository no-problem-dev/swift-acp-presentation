import Testing
import ACPCore
@testable import ACPPresentation

@Suite("Session view state")
struct SessionViewStateTests {
    @Test("reduces an ACP session/update stream into semantic UI state")
    func reducesStream() {
        let updates: [SessionUpdate] = [
            .plan(Plan(entries: [PlanEntry(content: "search the web", priority: .high, status: .inProgress)])),
            .agentThoughtChunk(ContentChunk(content: .text(TextContent(text: "I should search")))),
            .toolCall(ToolCall(toolCallId: ToolCallId("t1"), title: "search", kind: .search, status: .inProgress)),
            .toolCallUpdate(ToolCallUpdate(toolCallId: ToolCallId("t1"), status: .completed)),
            .agentMessageChunk(ContentChunk(content: .text(TextContent(text: "the answer")))),
        ]

        let state = SessionViewState.reduce(updates)

        #expect(state.activity == .working)
        #expect(state.thoughts == ["I should search"])
        #expect(state.messages == ["the answer"])
        #expect(state.plan.count == 1)
        #expect(state.plan.first?.content == "search the web")

        // the tool call is correlated by id and ends completed, kept semantic
        #expect(state.toolCalls.count == 1)
        let call = try? #require(state.toolCalls.first)
        #expect(call?.id == ToolCallId("t1"))
        #expect(call?.kind == .search)
        #expect(call?.status == .completed)
    }

    @Test("an update for an unknown tool-call id is ignored")
    func ignoresUnknownToolCallUpdate() {
        var state = SessionViewState()
        state.apply(.toolCallUpdate(ToolCallUpdate(toolCallId: ToolCallId("ghost"), status: .failed)))
        #expect(state.toolCalls.isEmpty)
    }
}
