---
title: swift-acp-presentation README
created: 2026-06-27
tags: [swift, acp, presentation, spm]
status: active
---

# swift-acp-presentation

> ACP の `session/update` ストリームを UI-agnostic な `SessionViewState` に変換し、ユーザー向け文言をホスト側でカプセル化するプレゼンテーション層パッケージ。

## 概要

`swift-acp-presentation` は、[swift-acp](https://github.com/no-problem-dev/swift-acp) が提供するエージェント活動ストリーム（`SessionUpdate`）を画面描画に必要な状態へ変換する責務を担う。

ドメイン（エージェント・プロトコル）は意味論（`tool_call.kind == .search`）だけを送出し、「Web を検索しています」のような表示文言はこのパッケージ内の String Catalog にのみ置く設計になっている。これにより、文言変更やローカライズ対応がドメイン層を変更せず完結する。

### 提供モジュール

| モジュール | 説明 |
|---|---|
| `ACPPresentation` | `SessionViewState` リデューサーと `SessionCopy` コピー層を提供する |

### 主な型

| 型 | 種別 | 説明 |
|---|---|---|
| `SessionViewState` | struct | ACP `session/update` ストリームをリデュースした UI スナップショット |
| `SessionViewState.Activity` | enum | セッション全体の活動状態（`.idle` / `.working` / `.completed`） |
| `ToolCallView` | struct | ツールコールの ID・タイトル・種別・ステータスを保持する UI 向けビュー |
| `SessionCopy` | enum | ローカライズ済み文言を返すコピーレイヤー（状態を持たない名前空間） |

## 対応プラットフォーム

| プラットフォーム | 最低バージョン |
|---|---|
| iOS | 16.0 |
| macOS | 13.0 |
| tvOS | 16.0 |
| watchOS | 9.0 |
| visionOS | 1.0 |

## インストール

`Package.swift` に依存を追加する。

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

## 使い方

### SessionViewState — ストリームのリデュース

`apply(_:)` で 1 件ずつ適用するか、`reduce(_:)` で一括変換する。

```swift
import ACPCore
import ACPPresentation

// ストリームを一括リデュース
let updates: [SessionUpdate] = fetchSessionUpdates()
let state = SessionViewState.reduce(updates)

// ストリームをインクリメンタルに適用する場合
var state = SessionViewState()
for update in liveStream {
    state.apply(update)
    render(state)
}
```

### SessionViewState のプロパティ

```swift
// セッション全体の活動状態
switch state.activity {
case .idle:      // エージェントは待機中
case .working:   // ツール呼び出しまたは思考中
case .completed: // セッション完了
}

// 実行計画（エージェントが計画を報告した場合）
for entry in state.plan {
    print(entry.content)   // "search the web"
    print(entry.priority)  // .high / .medium / .low
    print(entry.status)    // .pending / .inProgress / .completed / ...
}

// ツールコール一覧（告知順、id で更新が相関付けられる）
for call in state.toolCalls {
    print(call.id)     // ToolCallId
    print(call.title)  // "search"
    print(call.kind)   // .search / .read / .edit / ...
    print(call.status) // .inProgress / .completed / .failed
}

// エージェントの回答テキスト（チャンク順）
let fullAnswer = state.messages.joined()

// エージェントの推論ログ（チャンク順）
let reasoningLog = state.thoughts.joined(separator: "\n")
```

### SessionCopy — ローカライズ済み文言の取得

```swift
import ACPPresentation

// ツール種別 → 実行中フレーズ（日本語: "Web を検索しています"）
let phrase = SessionCopy.toolActivity(.search)

// セッション活動状態 → ラベル（日本語: "作業しています"）
let label = SessionCopy.activity(.working)
```

#### 対応ツール種別と文言（日本語 / 英語）

| `ToolKind` | 日本語 | 英語 |
|---|---|---|
| `.read` | ファイルを読んでいます | Reading a file |
| `.edit` | 編集しています | Editing |
| `.search` | Web を検索しています | Searching the web |
| `.execute` | コマンドを実行しています | Running a command |
| `.fetch` | ページを読み込んでいます | Fetching a page |
| `.think` | 考えています | Thinking |
| その他 | ツールを使っています | Using a tool |

未知の `ToolKind` はフォールバックフレーズ（`tool.default`）を返す。

### SwiftUI での統合例

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

## アーキテクチャ上の位置づけ

```
swift-acp (ACPCore)
    └── SessionUpdate, ToolCall, ToolKind, Plan, ...
            │
            ▼
swift-acp-presentation (ACPPresentation)          ← このパッケージ
    ├── SessionViewState  — セマンティクスのリデュース
    └── SessionCopy       — ローカライズ済み文言の提供
            │
            ▼
Host App / SwiftUI View
    — SessionViewState のプロパティでビューを構築
    — SessionCopy で文言を取得
```

- `swift-acp` はプロトコルとドメイン型のみを保持する。文言を持たない。
- `swift-acp-presentation` がプレゼンテーション責務を担う。ドメインへの依存は `ACPCore` のみ。
- ホストアプリはこのパッケージを経由して状態と文言を取得し、SwiftUI ビューを構築する。

## ライセンス

MIT License — 詳細は [LICENSE](./LICENSE) を参照。

---

最終更新: 2026-06-27
