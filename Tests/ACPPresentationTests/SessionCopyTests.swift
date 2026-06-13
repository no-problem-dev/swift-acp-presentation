import Testing
import ACPCore
@testable import ACPPresentation

@Suite("Session copy")
struct SessionCopyTests {
    @Test("tool kinds resolve to distinct, non-empty localized phrases")
    func toolActivityPhrases() {
        let search = SessionCopy.toolActivity(.search)
        let fetch = SessionCopy.toolActivity(.fetch)

        #expect(!search.isEmpty)
        #expect(!fetch.isEmpty)
        #expect(search != fetch)
        #expect(search != "tool.search") // resolved from the catalog, not the raw key
    }

    @Test("an unknown tool kind falls back to the default phrase")
    func unknownKindFallsBack() {
        let custom = SessionCopy.toolActivity(ToolKind("teleport"))
        #expect(custom == SessionCopy.toolActivity(ToolKind("other")))
        #expect(!custom.isEmpty)
    }

    @Test("activities resolve to distinct phrases")
    func activityPhrases() {
        #expect(SessionCopy.activity(.working) != SessionCopy.activity(.completed))
        #expect(!SessionCopy.activity(.idle).isEmpty)
    }
}
