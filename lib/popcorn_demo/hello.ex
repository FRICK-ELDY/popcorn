defmodule PopcornDemo.Hello do
	@moduledoc false

	@doc """
	シンプルな Hello ログを出力します。
	"""
	def run do
		IO.puts("Hello from WASM!")
		:ok
	end
end


