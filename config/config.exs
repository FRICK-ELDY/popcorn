import Config

# デフォルト（ローカル動作など）は `site/wasm` へ
config :popcorn, out_dir: "site/wasm"

# 環境別の設定を取り込む（home.exs / ticker.exs / parallel.exs など）
import_config "#{config_env()}.exs"

