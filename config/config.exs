import Config

# デモ配下で動かすため、WASM 出力先を `site/demo/wasm` に設定
config :popcorn, out_dir: "site/demo/wasm"

# 環境別の設定を取り込む（home.exs / ticker.exs / parallel.exs など）
env_cfg = Path.join(__DIR__, "#{config_env()}.exs")
if File.exists?(env_cfg) do
  import_config "#{config_env()}.exs"
end

