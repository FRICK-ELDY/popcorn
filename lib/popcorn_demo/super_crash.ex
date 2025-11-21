defmodule PopcornDemo.SuperCrash do
	@moduledoc false

	@max_restarts 5
	@interval_ms 100
	@counter_name __MODULE__.Counter

	def run(max \\ @max_restarts, interval_ms \\ @interval_ms) when max >= 0 and interval_ms > 0 do
		start_ms = System.monotonic_time(:millisecond)
		IO.puts("[sup] supervisor starting (max=#{max})")
		{:ok, _} = ensure_counter(%{max: max, start_ms: start_ms})

		children = [
			%{
				id: __MODULE__.Crashy,
				start: {__MODULE__.Crashy, :start_link, [%{interval_ms: interval_ms}]},
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

	defp ensure_counter(%{max: max, start_ms: start_ms}) do
		case Process.whereis(@counter_name) do
			nil ->
				GenServer.start(__MODULE__.Counter, %{max: max, start_ms: start_ms, count: 0}, name: @counter_name)
			pid when is_pid(pid) ->
				GenServer.call(@counter_name, {:reset, max, start_ms})
				{:ok, pid}
		end
	end

	defmodule Counter do
		use GenServer

		@impl true
		def init(%{max: max, start_ms: start_ms, count: count}) do
			{:ok, %{max: max, start_ms: start_ms, count: count}}
		end

		@impl true
		def handle_call(:next, _from, %{count: count} = state) do
			new_state = %{state | count: count + 1}
			{:reply, {new_state.count, state.start_ms, state.max}, new_state}
		end

		@impl true
		def handle_call({:reset, max, start_ms}, _from, _state) do
			{:reply, :ok, %{max: max, start_ms: start_ms, count: 0}}
		end
	end

	defmodule Crashy do
		use GenServer

		@counter PopcornDemo.SuperCrash.Counter

		def start_link(args), do: GenServer.start_link(__MODULE__, args)

		@impl true
		def init(%{interval_ms: t}) do
			{attempt, start_ms, max} = GenServer.call(@counter, :next)
			IO.puts("[sup] worker started")
			state = %{interval_ms: t, attempt: attempt, max: max, start_ms: start_ms}
			if attempt <= max do
                IO.puts("[sup] crashing (#{attempt}/#{max})")
				exit(:boom)
			else
				ms = System.monotonic_time(:millisecond) - start_ms
				IO.puts("[sup] recovered after #{max} restarts")
				IO.puts("[sup] done in #{ms} ms")
				{:ok, state}
			end
		end

		@impl true
		def handle_info(_msg, state), do: {:noreply, state}
	end
end
