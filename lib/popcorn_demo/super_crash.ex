defmodule PopcornDemo.SuperCrash do
	@moduledoc false

	@max_restarts 5

	def run(max \\ @max_restarts) when max >= 0 do
		start_ms = System.monotonic_time(:millisecond)
		IO.puts("[sup] supervisor starting (max=#{max})")

		children = [
			%{
				id: __MODULE__.Counter,
				start: {__MODULE__.Counter, :start_link, [%{max: max, start_ms: start_ms}]},
				restart: :permanent,
				shutdown: 2_000,
				type: :worker
			},
			%{
				id: __MODULE__.Crashy,
				start: {__MODULE__.Crashy, :start_link, [%{}]},
				restart: :permanent,
				shutdown: 2_000,
				type: :worker
			}
		]

		{:ok, _sup} =
			Supervisor.start_link(children,
				strategy: :one_for_one,
				max_restarts: max + 2,
				max_seconds: 2
			)
		:ok
	end

	defmodule Counter do
		use GenServer

		def start_link(%{max: max, start_ms: start_ms}) do
			GenServer.start_link(__MODULE__, %{max: max, start_ms: start_ms, attempt: 0}, name: __MODULE__)
		end

		@impl true
		def init(state), do: {:ok, state}

		@impl true
		def handle_call(:next, _from, %{attempt: a} = state) do
			new_attempt = a + 1
			{:reply, {new_attempt, state.start_ms, state.max}, %{state | attempt: new_attempt}}
		end
	end

	defmodule Crashy do
		use GenServer

		def start_link(args), do: GenServer.start_link(__MODULE__, args)

		@impl true
		def init(_args) do
			{attempt, start_ms, max} = GenServer.call(PopcornDemo.SuperCrash.Counter, :next)
			IO.puts("[sup] worker started")
			IO.puts("[sup] crashing (#{attempt}/#{max})")
			state = %{attempt: attempt, max: max, start_ms: start_ms}
			if attempt <= max do
				send(self(), :shutdown)
				{:ok, state}
			else
				ms = System.monotonic_time(:millisecond) - start_ms
				IO.puts("[sup] recovered after #{max} restarts")
				IO.puts("[sup] done in #{ms} ms")
				{:ok, state}
			end
		end

		@impl true
		def handle_info(:shutdown, state) do
			Process.exit(self(), :normal)
			{:noreply, state}
		end

		@impl true
		def handle_info(_msg, state), do: {:noreply, state}
	end
end
