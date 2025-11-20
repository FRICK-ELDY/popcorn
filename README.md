# Popcorn Demo

Elixir を WASM で動かすサンプルです。`site/demo/` にデモページ、`lib/popcorn_demo/` に Elixir 実装があります。

## 既存デモ
- Hello: "Hello from WASM!" を1回出力
- Ticker: 1秒ごとに10回出力
- Parallel: fib(30..32) を計算して出力
- PingPong: 2プロセスがメッセージを往復（10ラウンド）

## 追加デモの作り方
以下の流れで最小構成のデモを追加できます。

1) Elixir 側に `run/0` を作る

`lib/popcorn_demo/your_demo.ex` を作成し、固有の接頭辞でログを出します（例: `[yourdemo] ...`）。

```elixir
defmodule PopcornDemo.YourDemo do
	@moduledoc false

	def run do
		IO.puts("[yourdemo] started")
		# ここで処理を実行して適宜ログを出す
		IO.puts("[yourdemo] done")
		:ok
	end
end
```

2) 初期化完了後に `run/0` を呼ぶ

WASM 側のブリッジ初期化が完了した後に実行されるよう、`lib/popcorn_demo/worker.ex` の `handle_continue/2` に追記します。

```elixir
@impl true
def handle_continue(:after_init, state) do
	:ok = PopcornDemo.Hello.run()
	:ok = PopcornDemo.Parallel.run()
	:ok = PopcornDemo.PingPong.run()
	:ok = PopcornDemo.YourDemo.run()   # ← 追加
	{:noreply, state}
end
```

3) デモページを作る

`site/demo/your_demo.html` を追加し、共通ユーティリティ `runDemo` を使って必要なログだけを表示します。ナビは `injectNav()` で自動挿入します。

```html
<script type="module">
  import { runDemo } from "../assets/demo.js";
  import { injectNav } from "../assets/nav.js";
  injectNav();
  await runDemo({
    base: "./wasm",
    filter: (line) => line.startsWith("[yourdemo]"),
    transform: (line) => line.replace(/^\[yourdemo\]\s?/, "")
  });
</script>
```

4) ナビゲーションを更新

- `site/index.html` のリンクに追加
- 必要なら各デモページの `<div class="nav">` にもボタンを追加

## 共通フロントエンドユーティリティ

- `site/assets/demo.js`
  - `runDemo({ base, filter, transform, statusId, logsId, timeoutMs })`
  - `filter(line)`: 表示する行の判定
  - `transform(line)`: 表示前に整形（例: 接頭辞の除去）
  - 既知の初期化ノイズ（`AtomVM.mjs: ... Uncaught RuntimeError`）は抑制。`Aborted()`/`worker sent an error!` は表示

- `site/assets/nav.js`
  - `injectNav()`: 各ページの `<div class="nav"></div>` に共通ナビ（Hello/Ticker/Parallel/PingPong と `#status`）を挿入

### ページ雛形（最小）

```html
<div class="nav"></div>
<section id="logs-pane">
  <h3>Logs</h3>
  <pre id="logs"></pre>
</section>
<script type="module">
  import { injectNav } from "../assets/nav.js";
  import { runDemo } from "../assets/demo.js";
  injectNav();
  await runDemo({
    base: "./wasm",
    filter: (line) => line.startsWith("[yourdemo]"),
    transform: (line) => line.replace(/^\[yourdemo\]\s?/, "")
  });
</script>
```

## 表示ログのポリシー
- ページは `site/assets/demo.js` の `runDemo` でログを集約・表示します。
- 既知の初期化時ノイズを抑制しつつ、`Aborted()` や `worker sent an error!` は表示対象にしています。

## 開発メモ
- 依存: `mix deps.get && mix compile`
- 配信: `site/` を静的配信（例: GitHub Pages）
- 初期化順: `PopcornDemo.Worker` が最初に `Popcorn.Wasm.register(:main)` を実行し、その後に各 `run/0` を起動します。