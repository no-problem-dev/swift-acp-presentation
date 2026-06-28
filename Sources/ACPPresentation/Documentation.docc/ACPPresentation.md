# ``ACPPresentation``

ACP の `session/update` ストリームを UI 非依存のビューステートに変換し、全ユーザー向け文言を一元管理するプレゼンテーション層。

## Overview

`ACPPresentation` は ACP プロトコルが流すセマンティックなエージェント活動（ツール呼び出しの種別・状態、実行プラン、応答テキスト）を受け取り、SwiftUI などの View が直接バインドできる ``SessionViewState`` へ折りたたみます。

**セマンティクスと表現の分離**が設計の核心です。エージェントとプロトコルは「何が起きているか」という意味だけを送出し、「どう表示するか」「どう言葉にするか」はすべてこのライブラリが担います。"Searching the web" のような文言はここにしか存在しません。

### 状態の折りたたみ

``SessionViewState`` は ``SessionViewState/reduce(_:)`` でストリーム全体をまとめて、または ``SessionViewState/apply(_:)`` でイベントを 1 件ずつ積算して生成します。

```swift
import ACPPresentation
import ACPCore

// ストリーム全体をまとめて畳み込む
let state = SessionViewState.reduce(updates)

// 受信のたびにインクリメンタルに適用する
var state = SessionViewState()
for await update in session.updates {
    state.apply(update)
}
```

### 文言のローカライズ

``SessionCopy`` はツール種別やセッション全体のアクティビティを String Catalog（日本語デフォルト）でローカライズし、文字列として返します。View は ``SessionCopy/toolActivity(_:)`` や ``SessionCopy/activity(_:)`` を呼ぶだけで、ツール種別・状態ごとのラベルを得られます。

```swift
import ACPPresentation

// ツール呼び出し行の見出し
let label = SessionCopy.toolActivity(toolCallView.kind)  // 例: "ファイルを読み込み中"

// セッション全体のステータス表示
let status = SessionCopy.activity(state.activity)        // 例: "考え中…"
```

## Topics

### 状態モデル

- ``SessionViewState``
- ``ToolCallView``

### アクティビティ

- ``SessionViewState/Activity``

### ローカライズドテキスト

- ``SessionCopy``
