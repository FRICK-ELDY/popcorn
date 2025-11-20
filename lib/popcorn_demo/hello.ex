defmodule PopcornDemo.Hello do
	@moduledoc false

	def child_spec(_arg) do
		%{
			id: __MODULE__,
			start: {Task, :start_link, [fn -> run() end]},
			restart: :temporary,
			shutdown: 5_000,
			type: :worker
		}
	end

	@doc """
	シンプルな Hello ログを出力します。
	"""
	def run do
		IO.puts("Hello from WASM!")
		:ok
	end
end


