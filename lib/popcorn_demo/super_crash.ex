defmodule PopcornDemo.SuperCrash do
	@moduledoc false

	@max_restarts 5
	@interval_ms 100

	def run(max \\ @max_restarts, interval_ms \\ @interval_ms) when max >= 0 and interval_ms > 0 do
		start_ms = System.monotonic_time(:millisecond)
		IO.puts("[sup] supervisor starting (max=#{max})")
		{:ok, mgr} = GenServer.start_link(__MODULE__.Manager, %{max: max, start_ms: start_ms})
		GenServer.cast(mgr, :start)
		:ok
	end

	defmodule Manager do
		use GenServer

		def start_link(args), do: GenServer.start_link(__MODULE__, args)

		@impl true
		def init(%{max: max, start_ms: start_ms}) do
			{:ok, %{max: max, start_ms: start_ms, attempt: 0, child: nil, ref: nil}}
		end

		@impl true
		def handle_cast(:start, %{attempt: attempt, max: max} = state) do
			next = attempt + 1
			if next <= max do
				{:ok, pid} =
					PopcornDemo.SuperCrash.Crashy.start_link(%{attempt: next, max: max, start_ms: state.start_ms})
				ref = Process.monitor(pid)
				{:noreply, %{state | attempt: next, child: pid, ref: ref}}
			else
				ms = System.monotonic_time(:millisecond) - state.start_ms
				IO.puts("[sup] recovered after #{max} restarts")
				IO.puts("[sup] done in #{ms} ms")
				{:noreply, state}
			end
		end

		@impl true
		def handle_info({:DOWN, ref, :process, pid, reason}, %{ref: ref} = state) do
			GenServer.cast(self(), :start)
			{:noreply, %{state | child: nil, ref: nil}}
		end

		@impl true
		def handle_info(_msg, state), do: {:noreply, state}
	end

	defmodule Crashy do
		use GenServer

		def start_link(args), do: GenServer.start_link(__MODULE__, args)

		@impl true
		def init(%{attempt: attempt, max: max, start_ms: start_ms}) do
			IO.puts("[sup] worker started")
			IO.puts("[sup] crashing (#{attempt}/#{max})")
			# Supervisorを使わないので自力で即時終了を行う
			send(self(), :shutdown)
			state = %{attempt: attempt, max: max, start_ms: start_ms}
			{:ok, state}
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
