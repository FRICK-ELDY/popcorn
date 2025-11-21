defmodule PopcornDemo.SuperCrash do
	@moduledoc false

	@max_restarts 5

	def run(max \\ @max_restarts, interval_ms \\ @interval_ms) when max >= 0 and interval_ms > 0 do
		start_ms = System.monotonic_time(:millisecond)
		IO.puts("[sup] supervisor starting (max=#{max})")
		setup_ets(max, start_ms)

		children = [
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

	defp setup_ets(max, start_ms) do
		case :ets.whereis(:sup_demo) do
			:undefined -> :ets.new(:sup_demo, [:named_table, :public])
			_ -> :ok
		end
		:ets.insert(:sup_demo, {:restarts, 0})
		:ets.insert(:sup_demo, {:max, max})
		:ets.insert(:sup_demo, {:start_ms, start_ms})
	end

	defmodule Crashy do
		use GenServer

		def start_link(args), do: GenServer.start_link(__MODULE__, args)

		@impl true
		def init(_args) do
			attempt = :ets.update_counter(:sup_demo, :restarts, {2, 1}, {:restarts, 0})
			start_ms =
				case :ets.lookup(:sup_demo, :start_ms) do
					[{:start_ms, v}] -> v
					_ -> System.monotonic_time(:millisecond)
				end
			max =
				case :ets.lookup(:sup_demo, :max) do
					[{:max, v}] -> v
					_ -> 0
				end
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
