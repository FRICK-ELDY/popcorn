defmodule PopcornDemo.PingPong do
	@moduledoc false

	@rounds 10

	def run do
		{:ok, ping} = GenServer.start_link(__MODULE__.Ping, %{max: @rounds})
		{:ok, pong} = GenServer.start_link(__MODULE__.Pong, %{ping: ping})
		:ok = GenServer.call(ping, {:start, pong})
		:ok
	end

	defmodule Ping do
		use GenServer

		@impl true
		def init(%{max: max}) do
			state = %{max: max, pong: nil}
			{:ok, state}
		end

		@impl true
		def handle_call({:start, pong}, _from, state) do
			send(pong, {:ping, 1})
			{:reply, :ok, %{state | pong: pong}}
		end

		@impl true
		def handle_info({:pong, n}, %{pong: pong, max: max} = state) do
			IO.puts("[pingpong] ping #{n}")
			if n >= max do
				IO.puts("[pingpong] done")
				{:noreply, state}
			else
				send(pong, {:ping, n + 1})
				{:noreply, state}
			end
		end
	end

	defmodule Pong do
		use GenServer

		@impl true
		def init(%{ping: ping}) do
			{:ok, %{ping: ping}}
		end

		@impl true
		def handle_info({:ping, n}, %{ping: ping} = state) do
			IO.puts("[pingpong] pong #{n}")
			send(ping, {:pong, n})
			{:noreply, state}
		end
	end
end


