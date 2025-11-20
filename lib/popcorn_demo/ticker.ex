defmodule PopcornDemo.Ticker do
	use GenServer

	@moduledoc false

	@default_name __MODULE__

	def start, do: start_link([])

	def start_link(opts \\ []) do
		GenServer.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, @default_name))
	end

	@impl true
	def init(:ok) do
		IO.puts("[ticker] started")
		state = %{count: 0, ticker: :running}
		{:ok, state, 1_000}
	end

	@impl true
	def handle_info(:timeout, %{count: count, ticker: :running} = state) do
		new_count = count + 1
		IO.puts("[ticker] tick #{new_count}")

		if new_count >= 10 do
			IO.puts("[ticker] done")
			{:noreply, %{state | count: new_count, ticker: :stopped}}
		else
			{:noreply, %{state | count: new_count}, 1_000}
		end
	end

	@impl true
	def handle_info(_msg, state) do
		{:noreply, state}
	end
end


