defmodule PopcornDemo.SuperCrash do
	@moduledoc false

	@max_restarts 5
	@interval_ms 100

	def run(max \\ @max_restarts, interval_ms \\ @interval_ms) when max >= 0 and interval_ms > 0 do
		reset_counters()
		IO.puts("[sup] supervisor starting (max=#{max})")

		children = [
			{__MODULE__.Crashy, %{max: max, interval_ms: interval_ms}}
		]

		{:ok, _sup} = Supervisor.start_link(children, strategy: :one_for_one)
		:ok
	end

	defp reset_counters do
		case :ets.whereis(:sup_demo) do
			:undefined ->
				:ets.new(:sup_demo, [:named_table, :public, {:read_concurrency, true}])
			_ ->
				:ok
		end

		:ets.insert(:sup_demo, {:restarts, 0})
		:ets.insert(:sup_demo, {:start_ms, System.monotonic_time(:millisecond)})
	end

	defmodule Crashy do
		use GenServer

		def start_link(args), do: GenServer.start_link(__MODULE__, args)

		@impl true
		def init(%{max: max, interval_ms: t}) do
			IO.puts("[sup] worker started")
			Process.send_after(self(), :crash, t)
			{:ok, %{max: max, interval_ms: t}}
		end

		@impl true
		def handle_info(:crash, %{max: max, interval_ms: t} = state) do
			count = :ets.update_counter(:sup_demo, :restarts, {2, 1}, {:restarts, 0})

			if count <= max do
				IO.puts("[sup] crashing (#{count}/#{max})")
				raise "boom"
			else
				now = System.monotonic_time(:millisecond)
				case :ets.lookup(:sup_demo, :start_ms) do
					[{:start_ms, start}] ->
						ms = now - start
						IO.puts("[sup] recovered after #{max} restarts")
						IO.puts("[sup] done in #{ms} ms")
					_ ->
						IO.puts("[sup] recovered")
				end
				{:noreply, state}
			end
		end

		@impl true
		def handle_info(_msg, state), do: {:noreply, state}
	end
end


